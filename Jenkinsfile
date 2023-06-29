pipeline {
    agent any
    environment {
        AWS_CREDENTIALS = credentials('aws_credentials')
        SNOW_CRED = credentials('snow_cred')
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
                sh 'snowsql -a $SNOWFLAKE_ACCOUNT -u ${SNOW_CRED_USR} -p ${SNOW_CRED_PSW} -q "CREATE STORAGE INTEGRATION s3_int TYPE = EXTERNAL_STAGE STORAGE_PROVIDER = S3 ENABLED = TRUE"'
            }
        }
        stage('Extract External ID and IAM User ARN') {
            steps {
                script {
                    def output = sh(returnStdout: true, script: 'snowsql -a $SNOWFLAKE_ACCOUNT -u ${SNOW_CRED_USR} -p ${SNOW_CRED_PSW} -q "DESCRIBE STORAGE INTEGRATION s3_int"')
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
                sh 'snowsql -a $SNOWFLAKE_ACCOUNT -u ${SNOW_CRED_USR} -p ${SNOW_CRED_PSW} -q "CREATE FILE FORMAT my_file_format TYPE = CSV"'
            }
        }
        stage('Create Snowflake Stage') {
            steps {
                sh 'snowsql -a $SNOWFLAKE_ACCOUNT -u ${SNOW_CRED_USR} -p ${SNOW_CRED_PSW} -q "CREATE OR REPLACE STAGE dev_convertr.stage.s3_stage URL=\'s3://$S3_BUCKET\' STORAGE_INTEGRATION = s3_int FILE_FORMAT = my_file_format"'
            }
        }
    }
}
