#!/bin/bash

# NOTE: BEFORE RUNNING YARN and AWS-CLI MUST BE INSTALLED IN YOUR SYSTEM

# Change these variables if you need to
AWS_REGION="ap-southeast-1"
CLOUDFORMATION_S3_STACK_NAME="mailgunwebhook-s3"
CLOUDFORMATION_MAIN_STACK_NAME="mailgunwebhook-main"
S3_BUCKET_NAME="mailgunwebhookbucket"
S3_Key="mailgunwebhooklambda.zip"
SNS_TOPIC_NAME="MailgunWebhookEvents"


# chose input than arguments for security purposes
read -s -p "Enter Github Auth Token: " GITHUB_TOKEN
echo
read -s -p "Enter Mailgun Webhook Signing Key: " MAILGUN_KEY
echo
read -p "Enter email for AWS SNS Subscription: " SNS_EMAIL
echo

set -eu

echo "Creating CloudFormation S3 Bucket Stack as location for lambda zip file upload"
aws cloudformation create-stack \
        --region $AWS_REGION \
        --no-cli-pager \
        --stack-name $CLOUDFORMATION_S3_STACK_NAME \
        --parameters ParameterKey=S3Bucket,ParameterValue=$S3_BUCKET_NAME \
        --template-body file://cloudformation-s3.yml

echo "Waiting for CloudFormation S3 Bucket Stack to finish..."
aws cloudformation wait stack-create-complete --stack-name $CLOUDFORMATION_S3_STACK_NAME --region $AWS_REGION


echo "Finished creating CloudFormation S3 Stack"

echo "Installing project dependencies"
cd lambda-node
yarn install

echo "Creating lambda fuction zip file to be uploaded to created S3 Bucket"

if [ -f $S3_Key ]; then
   rm $S3_Key
   echo "$S3_Key file is removed for new build"
fi

yarn build-zip

echo "Uploading lambda function zip file to s3"
aws s3 cp ./$S3_Key  s3://$S3_BUCKET_NAME

echo "Creating CloudFormation Main Stack"
cd ..

aws cloudformation create-stack \
        --region $AWS_REGION \
        --no-cli-pager \
        --stack-name $CLOUDFORMATION_MAIN_STACK_NAME \
        --capabilities CAPABILITY_IAM \
        --template-body file://cloudformation-api-lambda-dynamodb-sns-cb.yml \
        --parameters ParameterKey=S3Bucket,ParameterValue=$S3_BUCKET_NAME ParameterKey=GitHubToken,ParameterValue=$GITHUB_TOKEN ParameterKey=MailgunSigningKey,ParameterValue=$MAILGUN_KEY ParameterKey=SNSSubscriptionEmail,ParameterValue=$SNS_EMAIL ParameterKey=SNSTopicName,ParameterValue=$SNS_TOPIC_NAME

echo "Waiting for CloudFormation Main Stack to finish..."
aws cloudformation wait stack-create-complete --stack-name $CLOUDFORMATION_MAIN_STACK_NAME --region $AWS_REGION

echo "Finished creating CloudFormation Main Stack"
echo "Executed CloudFormation Create Commands"
