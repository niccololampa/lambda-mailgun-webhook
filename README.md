# Mailgun Webhook SWS Lambda DyanamoDB and SNS Notification Service


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

