pipeline {
    agent any
    environment {
        AWS Credentials = credentials('aws_credentials')
        SNOWFLAKE_ACCOUNT = 'itb89569.us-east-1'
        S3_BUCKET = 'snowflake-input11'
        IAM_ROLE_NAME = 'snow-role'
    }
    stages {
        stage('Create AWS IAM Role') {
            steps {
                sh "aws iam create-role --role-name $IAM_ROLE_NAME --assume-role-policy-document file://trust-policy.json --aws-access-key-id ${AWS_CREDENTIALS_USR} --aws-secret-access-key ${AWS_CREDENTIALS_PSW}"
            }
        }
        stage('Create Storage Integration') {
            steps {
                sh 'sudo -u ec2-user snowsql -c my_connection -q "CREATE OR REPLACE STORAGE INTEGRATION s3_int TYPE = EXTERNAL_STAGE STORAGE_PROVIDER = S3 ENABLED = TRUE"'
            }
        }
        stage('Extract External ID and IAM User ARN') {
            steps {
                script {
                    def output = sh(returnStdout: true, script: 'sudo -u ec2-user snowsql -c my_connection -q "DESCRIBE STORAGE INTEGRATION s3_int"')
                    def matchExternalId = output =~ /STORAGE_AWS_EXTERNAL_ID=(\S+)/
                    def matchIamUserArn = output =~ /STORAGE_AWS_IAM_USER_ARN=(\S+)/
                    def externalId = matchExternalId[0][1]
                    def iamUserArn = matchIamUserArn[0][1]
                    sh "aws iam update-assume-role-policy --role-name $IAM_ROLE_NAME --policy-document file://trust-policy-updated.json --region us-east-1 --profile my-aws-profile --external-id $externalId --aws-iam-user-arn $iamUserArn"
                }
            }
        }
        stage('Confirm Connection and Create File Format') {
            steps {
                sh 'sudo -u ec2-user snowsql -c my_connection -q "CREATE OR REPLACE FILE FORMAT my_file_format TYPE = CSV"'
            }
        }
        stage('Create Snowflake Stage') {
            steps {
                sh 'sudo -u ec2-user snowsql -c my_connection -q "CREATE OR REPLACE STAGE dev_convertr.stage.s3_stag URL=\'s3://$S3_BUCKET\' STORAGE_INTEGRATION = s3_int FILE_FORMAT = my_file_format"'
            }
        }
    }
}
