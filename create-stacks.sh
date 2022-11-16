#!/bin/bash

# *** Change this to the desired name of the Cloudformation stack of 
# your Pipeline (*not* the stack name of your app)
AWS_REGION="ap-southeast-1"
CLOUDFORMATION_S3_STACK_NAME="mailgunwebhook-s3"
CLOUDFORMATION_MAIN_STACK_NAME="mailgunwebhook-main"
S3_BUCKET_NAME="mailgunwebhookbucket"
S3_Key="mailgunwebhooklambda.zip"


if [ -z ${1} ]
then
	echo "STACK CREATION FAILED!- No Github Token"
        echo "Pass your Github token as the first argument"
	exit 1
fi

if [ -z ${2} ]
then
	echo "STACK CREATION FAILED!- No Mailgun Signing Key"
        echo "Pass Mailgun webhook signing key as the second argument"
	exit 1
fi

if [ -z ${3} ]
then
	echo "STACK CREATION FAILED!- No SNS subscription email"
        echo "Pass email for SNS subscription signing key as the third argument"
	exit 1
fi

set -eu

echo "Creating CloudFormation Stack for S3 Bucket lambda zip file"
aws cloudformation create-stack \
        --region $AWS_REGION \
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
        --stack-name $CLOUDFORMATION_MAIN_STACK_NAME \
        --capabilities CAPABILITY_IAM \
        --template-body file://cloudformation-api-lambda-dynamodb-sns-cb.yml \
        --parameters ParameterKey=S3Bucket,ParameterValue=$S3_BUCKET_NAME ParameterKey=GitHubToken,ParameterValue=${1} ParameterKey=MailgunSigningKey,ParameterValue=${2} ParameterKey=SNSSubscriptionEmail,ParameterValue=${3}


