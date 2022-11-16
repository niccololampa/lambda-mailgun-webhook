#!/bin/bash

# NOTE: BEFORE RUNNING YARN and AWS-CLI MUST BE INSTALLED IN YOUR SYSTEM

# Change these variables if you need to
AWS_REGION="ap-southeast-1"
CLOUDFORMATION_S3_STACK_NAME="mailgunwebhook-s3-y"
CLOUDFORMATION_MAIN_STACK_NAME="mailgunwebhook-main"
S3_BUCKET_NAME="mailgunwebhookbucket"
S3_Key="mailgunwebhooklambda.zip"


# chose input than arguments for security purposes
read -s -p "Enter Github Auth Token: " GITHUB_TOKEN
echo
read -s -p "Enter Mailgun Webhook Signing Key: " MAILGUN_KEY
echo
read -p "Enter email for AWS SNS Subscription: " SNS_EMAIL
echo

set -eu

echo "Creating CloudFormation Stack for S3 Bucket lambda zip file"
aws cloudformation create-stack \
        --region $AWS_REGION \
        --no-cli-pager \
        --stack-name $CLOUDFORMATION_S3_STACK_NAME \
        --parameters ParameterKey=S3Bucket,ParameterValue=$S3_BUCKET_NAME \
        --template-body file://cloudformation-s3.yml

echo "Installing project dependencies"
cd lambda-node
yarn install

echo "Creating lambda fuction zip file to be uploaded to created S3 Bucket"
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
        --parameters ParameterKey=S3Bucket,ParameterValue=$S3_BUCKET_NAME ParameterKey=GitHubToken,ParameterValue=$GITHUB_TOKEN ParameterKey=MailgunSigningKey,ParameterValue=$MAILGUN_KEY ParameterKey=SNSSubscriptionEmail,ParameterValue=$SNS_EMAIL

echo "Executed Cloud Formation Create Commands"
