pipeline {
    agent any

    stages {
        stage('Add Policy Document') {
            steps {
                script {
                    def policyDocument = '''
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
                                    "Resource": "arn:aws:s3:::snowflake-input12"
                                },
                                {
                                    "Effect": "Allow",
                                    "Action": [
                                        "s3:ListBucket",
                                        "s3:GetBucketLocation"
                                    ],
                                    "Resource": "arn:aws:s3:::<bucket>",
                                    "Condition": {
                                        "StringLike": {
                                            "s3:prefix": [
                                                "<prefix>/*"
                                            ]
                                        }
                                    }
                                }
                            ]
                        }
                    '''

                    def bucketARN = "arn:aws:s3:::<bucket>"
                    def folderPrefix = "<prefix>"

                    withAWS(credentials: 'aws_credentials') {
                        sh """
                            aws s3api put-bucket-policy --bucket ${bucketARN} --policy '${policyDocument}'
                        """
                        sh """
                            aws s3api put-bucket-tagging --bucket ${bucketARN} --tagging 'TagSet=[{Key=FolderPrefix,Value=${folderPrefix}}]'
                        """
                    }
                }
            }
        }

        stage('Create IAM Role') {
            steps {
                script {
                    def awsAccountId = "988231236474"
                    def dummyExternalId = "00000"

                    def roleName = "snowflake-role"

                    def trustPolicyDocument = '''
                        {
                            "Version": "2012-10-17",
                            "Statement": [
                                {
                                    "Effect": "Allow",
                                    "Principal": {
                                        "AWS": "arn:aws:iam::${awsAccountId}:root"
                                    },
                                    "Action": "sts:AssumeRole",
                                    "Condition": {
                                        "StringEquals": {
                                            "sts:ExternalId": "${dummyExternalId}"
                                        }
                                    }
                                }
                            ]
                        }
                    '''

                    withAWS(credentials: 'aws_credentials') {
                        sh """
                            aws iam create-role --role-name ${roleName} --assume-role-policy-document '${trustPolicyDocument}' --tags Key=SnowflakeIntegration,Value=true
                        """
                        sh """
                            aws iam attach-role-policy --role-name ${roleName} --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
                        """
                    }
                }
            }
        }

        stage('Create Snowflake Storage Integration') {
            steps {
                script {
                    def integrationQuery = '''
                        sudo -u ec2-user snowsql -c my_connection -q "create or replace storage integration s3_integration
                            TYPE = EXTERNAL_STAGE
                            STORAGE_PROVIDER = S3
                            ENABLED = TRUE 
                            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<aws_account_id>:role/snowflake-role'
                            STORAGE_ALLOWED_LOCATIONS = ('s3://snowflake-input12')"
                    '''

                    withAWS(credentials: 'aws_credentials') {
                        // Add code to execute the Snowflake storage integration query here
                    }
                }
            }
        }

        stage('Retrieve AWS IAM User') {
            steps {
                script {
                    def integrationName = "s3_integration"

                    def integrationDescriptionQuery = '''
                        DESCRIBE INTEGRATION ''' + integrationName + ''';
                    '''

                    def integrationDescriptionOutput = withAWS(credentials: 'aws_credentials') {
                        sh(
                            script: "sudo -u ec2-user snowsql -c my_connection -q '${integrationDescriptionQuery}'",
                            returnStdout: true
                        ).trim()
                    }

                    // Parse the output to extract STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID
                    def userArn = integrationDescriptionOutput =~ /STORAGE_AWS_IAM_USER_ARN\s*\|\s*(.*?)\s*\|/
                    def externalId = integrationDescriptionOutput =~ /STORAGE_AWS_EXTERNAL_ID\s*\|\s*(.*?)\s*\|/

                    // Get the matched values
                    def storageAwsIamUserArn = userArn ? userArn[0][1] : null
                    def storageAwsExternalId = externalId ? externalId[0][1] : null

                    // Use the extracted values for further steps
                    echo "Storage AWS IAM User ARN: ${storageAwsIamUserArn}"
                    echo "Storage AWS External ID: ${storageAwsExternalId}"
                }
            }
        }

        stage('Grant IAM User Permissions') {
            steps {
                script {
                    def policyDocument = '''
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
                                            "sts:ExternalId": "<snowflake_external_id>"
                                        }
                                    }
                                }
                            ]
                        }
                    '''

                    // Update the IAM role trust relationship with the policy document
                    def roleName = "snowflake-role"
                    withAWS(credentials: 'aws_credentials') {
                        sh """
                            aws iam update-assume-role-policy --role-name ${roleName} --policy-document '${policyDocument}'
                        """
                    }
                }
            }
        }
    }
}
