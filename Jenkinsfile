pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '988231236474'
        S3_BUCKET = 'snowflake-input12'
        IAM_ROLE_NAME = 'snowflake-role'
        IAM_POLICY_NAME = 'snowpolicy'
        IAM_POLICY_ARN = "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${IAM_POLICY_NAME}"
        IAM_ROLE_ARN = "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${IAM_ROLE_NAME}"
        SNOWFLAKE_STAGE = 's3_stage'
        SNOWFLAKE_FILE_FORMAT = 'my_file_format'
    }

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


        stage('Create Storage Integration') {
            steps {
                sh "sudo -u ec2-user snowsql -c my_connection -q \"create storage integration s3_int type = external_stage storage_provider = s3 storage_aws_role_arn = '${IAM_ROLE_ARN}' storage_allowed_locations = ('${S3_BUCKET}')\""
            }
        }

        stage('Extract AWS External ID and IAM User ARN') {
            steps {
                script {
                    def query = "select SYSTEM$PIPE_ENCRYPT(AWS_EXTERNAL_ID) as STORAGE_AWS_EXTERNAL_ID, SYSTEM$PIPE_ENCRYPT(AWS_IAM_USER_ARN) as STORAGE_AWS_IAM_USER_ARN from table(information_schema.storage_integrations) where integration_name = 'S3_INT'"
                    def result = sh(script: "sudo -u ec2-user snowsql -c my_connection -q \"${query}\" --csv", returnStdout: true)
                    def rows = result.trim().split('\n')
                    def columns = rows[0].split(',')
                    def values = rows[1].split(',')
                    env.STORAGE_AWS_EXTERNAL_ID = columns[0]
                    env.STORAGE_AWS_IAM_USER_ARN = columns[1]
                }
            }
        }

       stage('Update IAM Role Trust Relationship') {
            steps {
                script {
                    def trustPolicy = readJSON file: 'trust-policy.json'
                    trustPolicy.Statement[0].Principal.AWS = env.STORAGE_AWS_IAM_USER_ARN
                    trustPolicy.Statement[0].Condition.StringEquals['snowflake:externalId'] = env.STORAGE_AWS_EXTERNAL_ID
                    writeFile file: 'trust-policy.json', text: groovy.json.JsonOutput.toJson(trustPolicy)
                }
                withCredentials([aws(credentialsId: 'aws_credentials', region: "${AWS_REGION}")]) {
                    sh "aws iam update-assume-role-policy --role-name ${IAM_ROLE_NAME} --policy-document file://trust-policy.json"
                }
            }
        }

        stage('Create Snowflake Stage') {
            steps {
                sh "sudo -u ec2-user snowsql -c my_connection -q \"create or replace stage ${SNOWFLAKE_STAGE} url='s3://${S3_BUCKET}' storage_integration = s3_int file_format = ${SNOWFLAKE_FILE_FORMAT}\""
            }
        }
    }
}