pipeline {
    agent any
    stages {
        stage('Create AWS Role') {
            steps {
                script {
                    def trust_policy_document = """
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::988231236474:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "000000"
                }
            }
        }
    ]
}
"""

                    trust_policy_document = trust_policy_document.strip()

                    withAWS(credentials: 'aws_credentials') {
                        writeFile file: 'trust-policy.json', text: trust_policy_document
                        sh 'aws iam create-role --role-name snowflake-role --assume-role-policy-document file://trust-policy.json'
                    }
                }
            }
        }

        stage('Create Snowflake Storage Integration') {
            steps {
                sh '''
sudo -u ec2-user snowsql -c my_connection -q "create or replace storage integration s3_integration
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE 
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::988231236474:role/snowflake-role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://snowflake-input12')"
'''
            }
        }

        stage('Fetch Storage AWS IAM User ARN and External ID') {
            steps {
                script {
                    def result = sh (
                        script: "sudo -u ec2-user snowsql -c my_connection -q 'select aws_role_arn, aws_external_id from information_schema.integrations where name = \\'s3_integration\\''",
                        returnStdout: true
                    ).trim()

                    // Extract the AWS IAM User ARN and External ID from the command output
                    def awsRoleArn = result =~ /(?<=AWS_ROLE_ARN\s+\|\s+).*$/m
                    def awsExternalId = result =~ /(?<=AWS_EXTERNAL_ID\s+\|\s+).*$/m

                    // Print the extracted values
                    echo "AWS IAM User ARN: ${awsRoleArn[0]}"
                    echo "AWS External ID: ${awsExternalId[0]}"
                }
            }
        }

        stage('Update AWS Role Trust Relationship') {
            steps {
                withAWS(credentials: 'aws_credentials') {
                    sh 'aws iam update-assume-role-policy --role-name snowflake-role --policy-document file://trust-policy.json'
                }
            }
        }

        stage('Create Stage in Snowflake Account Using Storage Int and S3 URL') {
            steps {
                sh '''
sudo -u ec2-user snowsql -c my_connection -q "create or replace stage dev_convertr.stage.s3_stage url='s3://snowflake-input12'
    STORAGE_INTEGRATION = s3_integration
    FILE_FORMAT = dev_convertr.stage.my_file_format"
'''
            }
        }
    }
}
