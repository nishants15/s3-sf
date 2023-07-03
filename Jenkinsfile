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
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "STORAGE_AWS_EXTERNAL_ID"
        },
        "StringLike": {
          "sts:ExternalId": "arn:aws:iam::*:user/STORAGE_AWS_IAM_USER_ARN"
        }
      }
    }
  ]
}
"""

pipeline {
    agent any

    stages {
        stage('Create AWS IAM Role') {
            steps {
                withAWS(credentials: awsCredentialsId) {
                    script {
                        def roleExists = sh(
                            script: 'aws iam get-role --role-name snowflake-role',
                            returnStatus: true
                        ) == 0

                        if (!roleExists) {
                            sh '''
                            aws iam create-role --role-name snowflake-role --assume-role-policy-document file:///home/ec2-user/iam-policy.json
                            '''
                        } else {
                            echo "Role 'snowflake-role' already exists."
                        }
                    }
                }
            }
        }

        stage('Create Storage Integration with S3 URL in Snowflake') {
            steps {
                sh '''
                sudo -u ec2-user snowsql -c my_connection -q "create or replace storage integration s3_int type='S3' url='s3://snowflake-input12'"
                '''
            }
        }

        stage('Extract STORAGE_AWS_EXTERNAL_ID and STORAGE_AWS_IAM_USER_ARN from Snowflake') {
            steps {
                script {
                    def output = sh '''
                        sudo -u ec2-user snowsql -c my_connection -q "select STORAGE_AWS_EXTERNAL_ID, STORAGE_AWS_IAM_USER_ARN from storage_integrations where name='s3_int'"
                        '''
                    
                    def json = readJSON text: output.trim()

                    def STORAGE_AWS_EXTERNAL_ID = json[0].STORAGE_AWS_EXTERNAL_ID
                    def STORAGE_AWS_IAM_USER_ARN = json[0].STORAGE_AWS_IAM_USER_ARN

                    // Update IAM policy with extracted values
                    def updatedIAMPolicy = iamPolicy.replace("STORAGE_AWS_EXTERNAL_ID", STORAGE_AWS_EXTERNAL_ID)
                                                     .replace("STORAGE_AWS_IAM_USER_ARN", STORAGE_AWS_IAM_USER_ARN)

                    // Save the updated IAM policy to a file
                    writeFile file: "/home/ec2-user/updated-iam-policy.json", text: updatedIAMPolicy
                }
            }
        } 

        stage('Update IAM Role Trust Relationship with STORAGE_AWS_EXTERNAL_ID and STORAGE_AWS_IAM_USER_ARN') {
            steps {
                withAWS(credentials: awsCredentialsId) {
                    sh '''
                    aws iam update-assume-role-policy --role-name snowflake-role --policy-document file:///home/ec2-user/updated-iam-policy.json
                    '''
                }
            }
        }

        stage('Confirm Connection Between AWS Role and Snowflake') {
            steps {
                sh '''
                sudo -u ec2-user snowsql -c my_connection -q "create file format my_file_format type='CSV'"
                '''
            }
        }

        stage('Create Stage in Snowflake Account Using Storage Int and S3 URL') {
            steps {
                sh '''
                sudo -u ec2-user snowsql -c my_connection -q "create or replace stage dev_convertr.stage.s3_stage url='s3://snowflake-input12'
                STORAGE_INTEGRATION = s3_int
                FILE_FORMAT = dev_convertr.stage.my_file_format;"
                '''
            }
        }
    }
}
