import AWS = require("aws-sdk")
import crypto = require("crypto")

AWS.config.update({ region: process.env.AWS_REGION_SELECTED })
const dynamo = new AWS.DynamoDB.DocumentClient()

// provide by secrets. Also encrypt using AWS key manager.
const signingKey = process.env.SIGNING_KEY

// function to verify if event comes from mailgun
const verify = ({
    timestamp,
    token,
    signature,
}: {
    timestamp: string
    token: string
    signature: string
}) => {
    const encodedToken = crypto
        .createHmac("sha256", signingKey)
        .update(timestamp.concat(token))
        .digest("hex")

    return encodedToken === signature
}

exports.handler = async (event: any) => {
    const eventJSON = JSON.parse(event.body)
    let statusCode = "200"
    let dbwrite = true
    let snsPublished = false

    const { timestamp, token, signature } = eventJSON.signature

    // confirm if mailgun event
    const verified = verify({ timestamp, token, signature })

    // do not process the request if not a mailgun event
    if (!verified) {
        return {
            statusCode: 403,
            headers: {
                "Content-Type": "application/json",
            },
            body: { error: "Unauthorized" },
        }
    }

    // Log for CloudWatch
    console.log(event)

    // create DynamoDB Table  "MailGunWebHookEvents" in Singapore region. with id (string) as partition key and date (number) as sort key
    // make sure Lambda function has permissions to write to DynamoDB.
    const dynamoParam = {
        Item: {
            id: eventJSON["event-data"].id,
            date: Date.now(),
            webhookMap: eventJSON,
            webHookString: JSON.stringify(eventJSON),
        },
        TableName: process.env.DYNAMO_DB_TABLE_NAME,
    }

    try {
        await dynamo.put(dynamoParam).promise()
    } catch (err) {
        statusCode = "400"
        dbwrite = false
        // body = err.message;
    }

    // publish SNS

    const snsMessage = {
        Provider: "MAILGUN",
        timestamp: eventJSON["signature"].timestamp,
        type: eventJSON["event-data"].event,
    }

    // Create promise and SNS service object
    const snsParams = {
        Message: JSON.stringify(snsMessage),
        TopicArn: process.env.SNS_TOPIC_ARN,
    }

    const publishTextPromise = new AWS.SNS({ apiVersion: "2010-03-31" })
        .publish(snsParams)
        .promise()

    // Handle promise's fulfilled/rejected states
    await publishTextPromise
        .then(function (data) {
            // Logs for Cloudwatch
            console.log(
                `Message ${snsParams.Message} sent to the topic ${snsParams.TopicArn}`
            )
            console.log("MessageID is " + data.MessageId)
            snsPublished = true
        })
        .catch(function (err) {
            console.error(err, err.stack)
        })

    const response = {
        statusCode,
        headers: {
            "Content-Type": "application/json",
        },
        isBase64Encoded: false,
        body: JSON.stringify({ dbwrite, snsPublished, snsMessage }),
    }

    return response
}
