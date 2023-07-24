pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = "988231236474" // Replace with your AWS Account ID
        EXTERNAL_ID = "0000" // Replace with your Snowflake External ID
        S3_BUCKET_NAME = "snowflake-input12"
        SNOWFLAKE_ROLE_ARN = "arn:aws:iam::${AWS_ACCOUNT_ID}:role/snowflake-role"
        SNOWFLAKE_INTEGRATION_NAME = "s3_integration"
    }

    stages {
        stage('Set Up IAM Role') {
            steps {
                script {
                    def trustPolicy = '''
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${env.STORAGE_AWS_IAM_USER_ARN}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${env.SNOWFLAKE_EXTERNAL_ID}"
        }
      }
    }
  ]
}
'''
                    withAWS(credentials: 'aws_credentials') {
                        def iamRoleName = 'snowflake-iam-role'
                        def iamRoleArn = sh(script: 'aws iam create-role --role-name ' + iamRoleName + ' --assume-role-policy-document \'' + trustPolicy + '\'', returnStdout: true).trim()
                        sh(script: 'aws iam attach-role-policy --role-name ' + iamRoleName + ' --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess') // Assuming Snowflake needs full access to S3
                        sh(script: 'aws iam create-instance-profile --instance-profile-name ' + iamRoleName)
                        sh(script: 'aws iam add-role-to-instance-profile --instance-profile-name ' + iamRoleName + ' --role-name ' + iamRoleName)
                        env.IAM_ROLE_ARN = iamRoleArn
                    }
                }
            }
        }

        stage('Create Snowflake Storage Integration') {
            steps {
                script {
                    withAWS(credentials: 'aws_credentials') {
                        sh '''
                        sudo -u ec2-user snowsql -c my_connection -q "create or replace storage integration ${env.SNOWFLAKE_INTEGRATION_NAME}
                            TYPE = EXTERNAL_STAGE
                            STORAGE_PROVIDER = S3
                            ENABLED = TRUE 
                            STORAGE_AWS_ROLE_ARN = '${env.IAM_ROLE_ARN}'
                            STORAGE_ALLOWED_LOCATIONS = ('s3://${env.S3_BUCKET_NAME}')"
                        '''
                    }
                }
            }
        }

        stage('Retrieve AWS IAM User and External ID') {
            steps {
                script {
                    withAWS(credentials: 'aws_credentials') {
                        def integrationInfo = sh(script: "sudo -u ec2-user snowsql -c my_connection -q 'DESC INTEGRATION ${env.SNOWFLAKE_INTEGRATION_NAME};'", returnStdout: true)
                        env.SNOWFLAKE_USER_ARN = integrationInfo =~ /STORAGE_AWS_IAM_USER_ARN\s*\|\s*String\s*\|\s*([^|]+)/ ? ~/arn:aws:iam::\d+:user\/.*/.matcher(~/\s*([^|]+)\s*/.matcher(integrationInfo[0][0]).replaceAll('$1')).replaceAll('$1') : null
                        env.SNOWFLAKE_EXTERNAL_ID = integrationInfo =~ /STORAGE_AWS_EXTERNAL_ID\s*\|\s*String\s*\|\s*([^|]+)/ ? ~/([^|]+)/.matcher(~/\s*([^|]+)\s*/.matcher(integrationInfo[0][0]).replaceAll('$1')).replaceAll('$1') : null
                    }
                }
            }
        }

        stage('Grant IAM User Permissions to Access Bucket Objects') {
            steps {
                script {
                    withAWS(credentials: 'aws_credentials') {
                        def policyDocument = '''
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${env.SNOWFLAKE_USER_ARN}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${env.SNOWFLAKE_EXTERNAL_ID}"
        }
      }
    }
  ]
}
'''
                        sh(script: 'aws iam update-assume-role-policy --role-name snowflake-iam-role --policy-document \'' + policyDocument + '\'', returnStdout: true)
                    }
                }
            }
        }
    }
}
