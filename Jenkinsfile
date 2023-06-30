def awsCredentialsId = "aws_credentials"
def snowflakeConnection = "my_connection"

def iamPolicy = """
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
"""

pipeline {
    agent any

    stages {
        stage('Create AWS IAM Role') {
            steps {
                sh '''
                aws iam create-role --role-name snowflake-role --assume-role-policy-document file:///home/ec2-user/iam-policy.json
                '''
            }
        }

        stage('Create Storage Integration with S3 URL in Snowflake') {
            steps {
                sh '''
                snowsql -c "${snowflakeConnection}" -q "create or replace storage integration s3_int type='S3' url='s3://snowflake-input11'"
                '''
            }
        }

        stage('Extract STORAGE_AWS_EXTERNAL_ID and STORAGE_AWS_IAM_USER_ARN from Snowflake') {
            steps {
                sh '''
                snowsql -c "${snowflakeConnection}" -q "select STORAGE_AWS_EXTERNAL_ID, STORAGE_AWS_IAM_USER_ARN from storage_integrations where name='s3_int'"
                '''
            }
        }

        stage('Update IAM Role Trust Relationship with STORAGE_AWS_EXTERNAL_ID and STORAGE_AWS_IAM_USER_ARN') {
            steps {
                sh '''
                aws iam update-assume-role-policy --role-name snowflake-role --assume-role-policy-document file:///home/ec2-user/iam-policy.json
                '''
            }
        }

        stage('Confirm Connection Between AWS Role and Snowflake') {
            steps {
                sh '''
                snowsql -c "${snowflakeConnection}" -q "create file format my_file_format type='CSV'"
                '''
            }
        }

        stage('Create Stage in Snowflake Account Using Storage Int and S3 URL') {
            steps {
                sh '''
                snowsql -c "${snowflakeConnection}" -q "create or replace stage dev_convertr.stage.s3_stage url='s3://snowflake-input11'
                STORAGE_INTEGRATION = s3_int
                FILE_FORMAT = dev_convertr.stage.my_file_format;"
                '''
            }
        }
    }
}
