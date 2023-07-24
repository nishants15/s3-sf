pipeline {
    agent any

    stages {
        stage('Step 1: Add S3 Bucket Policy') {
            steps {
                script {
                    def bucketName = "snowflake-input12"
                    def folderPrefix = "snow"
                    def accountId = "988231236474"

                    def policy = '''
                    {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Effect": "Allow",
                                "Action": [
                                    "s3:PutObject",
                                    "s3:GetObject",
                                    "s3:GetObjectVersion",
                                    "s3:DeleteObject",
                                    "s3:DeleteObjectVersion"
                                ],
                                "Resource": "arn:aws:s3:::${bucketName}"
                            },
                            {
                                "Effect": "Allow",
                                "Action": [
                                    "s3:ListBucket",
                                    "s3:GetBucketLocation"
                                ],
                                "Resource": "arn:aws:s3:::${bucketName}",
                                "Condition": {
                                    "StringLike": {
                                        "s3:prefix": [
                                            "${folderPrefix}/*"
                                        ]
                                    }
                                }
                            }
                        ]
                    }
                    '''

                    withAWS(credentials: 'aws_credentials') {
                        sh "aws s3api put-bucket-policy --bucket ${bucketName} --policy '${policy}'"
                    }
                }
            }
        }

        stage('Step 2: Create IAM Role in AWS') {
            steps {
                script {
                    def accountId = "988231236474"
                    def externalId = "0000"

                    def trustPolicy = '''
                    {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Sid": "",
                                "Effect": "Allow",
                                "Principal": {
                                    "AWS": "<snowflake_user_arn>"
                                },
                                "Action": "sts:AssumeRole",
                                "Condition": {
                                    "StringEquals": {
                                        "sts:ExternalId": "${externalId}"
                                    }
                                }
                            }
                        ]
                    }
                    '''

                    withAWS(credentials: 'aws_credentials') {
                        // Create the IAM role with the trust policy
                        def roleName = "snowflake-role"
                        sh "aws iam create-role --role-name ${roleName} --assume-role-policy-document '${trustPolicy}'"

                        // Attach required policies to the role (if needed)
                        // sh "aws iam attach-role-policy --role-name ${roleName} --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess"
                    }
                }
            }
        }

        stage('Step 3: Create Snowflake Storage Integration') {
            steps {
                script {
                    def connectionName = "my_connection"
                    def roleName = "snowflake-role"
                    def bucketLocation = "s3://snowflake-input12"

                    def createIntegrationCommand = "sudo -u ec2-user snowsql -c ${connectionName} -q \"create or replace storage integration s3_integration "
                    createIntegrationCommand += "TYPE = EXTERNAL_STAGE "
                    createIntegrationCommand += "STORAGE_PROVIDER = S3 "
                    createIntegrationCommand += "ENABLED = TRUE "
                    createIntegrationCommand += "STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::${accountId}:role/${roleName}' "
                    createIntegrationCommand += "STORAGE_ALLOWED_LOCATIONS = ('${bucketLocation}')\""

                    sh createIntegrationCommand
                }
            }
        }
    }
}
