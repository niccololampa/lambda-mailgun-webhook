# Mailgun Webhook SWS Lambda DyanamoDB and SNS Notification Service

## Summary of Features 
- Saving in AWS DynamoDB of Mailgun Webhook details received via AWS API Gateway. 
- AWS SNS publish of Mailgun Webhook details to subscribed emails. 
- AWS CloudFormation automatic creation of required AWS resources to run this repo. (via bash script) 
- AWS Codebuild CI/CD to update AWS Lambda function upon merge of commits to this Github repo. 


## AWS CodeFormation Execution (Auto-creation of AWS Resources)

To create the necessary AWS resources, this repo implements infracstructure by code via CloudFormation. 

Run the following: 

```bash
chmod u+x create-cf-stacks.sh
./create-cf-stacks.sh
```
This script will automate the creation of the requires AWS resources (S3, Lambda, API Gateway,  DynamoDB, SNS, CodeBuild, IAM Roles).
![Screen Shot 2022-11-16 at 12 34 22 PM](https://user-images.githubusercontent.com/37615906/202223763-fea91a0f-0f90-42f0-acb1-2a3c8a34b0c6.png)


Once executed the terminal will prompt you for the Github Auth Token, Mailgun Webhook Signing Key and Email to be used for subscription.

The Github Token will be used for connecting your AWS account to github account for CodeBuild configurations. (CodeBuild will track github repo to update the AWS Lambda function) 

The mailgun signing key is used to verify that the hooks sent via API gateway are coming from the Mailgun account of the user. 

For  the Github Token and Mailgun  Signing key will be discussed here. 

You can customize the AWS resources by updating the variables section of `create-sf-stacks.sh` 
![Screen Shot 2022-11-16 at 11 23 57 PM](https://user-images.githubusercontent.com/37615906/202223528-16961e42-49a2-4586-8fe9-5a2d7507fedf.png)

## How to Test 

After executing the `create-cf-stacks.sh` scripts you can test the application by sending a mailgun webhook. To do this follow the following steps: 

### Confrim SNS Subscription

 Go to the email you provided and confirm subscription to SNS Topic.
![Screen Shot 2022-11-17 at 8 32 55 AM](https://user-images.githubusercontent.com/37615906/202324956-83db592a-e686-45ed-939e-9570c37bbf61.png)
![Screen Shot 2022-11-17 at 8 33 18 AM](https://user-images.githubusercontent.com/37615906/202324969-80712c0f-5c2f-4bf1-9999-793abb099607.png)

### Copy AWS API Gateway URL for mailgunwebhook.

Go to your [AWS API Gateway Page](https://ap-southeast-1.console.aws.amazon.com/apigateway/) and click on MailGunWebhook API.

Go to `Stages > / > /mailgunwebhook > POST` and copy the **Invoke URL**. 
![Screen Shot 2022-11-17 at 8 44 48 AM](https://user-images.githubusercontent.com/37615906/202326368-306c26c0-3e6c-474b-b5b7-d161f94c633e.png)


## Test Using Mailgun.com

Login to your account and Proceed to `Sending>Webhooks` then paste the copied API Gateway URL and test webhook.
![Screen Shot 2022-11-17 at 8 53 32 AM](https://user-images.githubusercontent.com/37615906/202327394-102fdd42-bb7b-4b44-ad36-2022bdf71aa9.png)

Once tested you will receive a response coming from our AWS Lambda Function. 












