pipeline {
    agent any
    environment {
        SNOW_CRED = credentials('snow_cred')
        SNOWFLAKE_ACCOUNT = 'itb89569.us-east-1'
        S3_BUCKET = 'snowflake-input11'
        IAM_ROLE_NAME = 'snow-role'
        TRUST_POLICY = '''{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "snowflake.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole",
                    "Condition": {
                        "StringEquals": {
                            "sts:ExternalId": "STORAGE_AWS_EXTERNAL_ID_VALUE",
                            "sts:aws:userid": "STORAGE_AWS_IAM_USER_ARN_VALUE"
                        }
                    }
                }
            ]
        }'''
    }
    stages {
        stage('Create AWS IAM Role') {
            steps {
                script {
                    def trustPolicy = TRUST_POLICY
                        .replace('STORAGE_AWS_EXTERNAL_ID_VALUE', '')
                        .replace('STORAGE_AWS_IAM_USER_ARN_VALUE', '')
                    withAWS(credentials: 'aws_credentials') {
                        sh "aws iam create-role --role-name $IAM_ROLE_NAME --assume-role-policy-document '$trustPolicy'"
                    }
                }
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
                    def output = sh(returnStdout: true, script: 'snowsql -a $SNOWFLAKE_ACCOUNT -u ${SNOW_CRED_USR} -p ${SNOW_CRED_PSW} -q "DESCRIBE STORAGE INTEGRATION s3_int"')
                    def matchExternalId = output =~ /STORAGE_AWS_EXTERNAL_ID=(\S+)/
                    def matchIamUserArn = output =~ /STORAGE_AWS_IAM_USER_ARN=(\S+)/
                    def externalId = matchExternalId[0][1]
                    def iamUserArn = matchIamUserArn[0][1]
                    def trustPolicyUpdated = TRUST_POLICY
                        .replace('STORAGE_AWS_EXTERNAL_ID_VALUE', externalId)
                        .replace('STORAGE_AWS_IAM_USER_ARN_VALUE', iamUserArn)
                    sh "aws iam update-assume-role-policy --role-name $IAM_ROLE_NAME --policy-document '$trustPolicyUpdated' --region us-east-1 --profile my-aws-profile"
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
