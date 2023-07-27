pipeline {
    agent any

    environment {
        STORAGE_AWS_IAM_USER_ARN = ""  // Declare the variable here
        STORAGE_AWS_EXTERNAL_ID = ""   // Declare the variable here
    }

    stages {
        stage('Create IAM Role') {
            steps {
                script {
                    withAWS(credentials: 'aws_credentials') {
                        def roleName = "snowflake-role"

                        sh "aws iam create-role --role-name ${roleName} --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}'"

                        sh "aws iam attach-role-policy --role-name ${roleName} --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/snowpolicy"

                        echo "IAM Role '${roleName}' with attached policy 'snowpolicy' created successfully."
                    }
                }
            }
        }

        stage('Create Snowflake Storage Integration') {
            steps {
                script {
                    withAWS(credentials: 'aws_credentials') {
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
            }
        }

        stage('Retrieve IAM User ARN and External ID') {
            steps {
                script {
                    withAWS(credentials: 'aws_credentials') {
                        def integrationOutput = sh(
                            script: "sudo -u ec2-user snowsql -c my_connection -q 'DESC INTEGRATION s3_integration;'",
                            returnStdout: true
                        )

                        // Extract STORAGE_AWS_IAM_USER_ARN
                        def arnMatcher = integrationOutput =~ /STORAGE_AWS_IAM_USER_ARN\s+\|\s+(\S+)/
                        if (arnMatcher) {
                            STORAGE_AWS_IAM_USER_ARN = arnMatcher[0][1]
                        } else {
                            error "Failed to find STORAGE_AWS_IAM_USER_ARN"
                        }

                        // Extract STORAGE_AWS_EXTERNAL_ID
                        def idMatcher = integrationOutput =~ /STORAGE_AWS_EXTERNAL_ID\s+\|\s+(\S+)/
                        if (idMatcher) {
                            STORAGE_AWS_EXTERNAL_ID = idMatcher[0][1]
                        } else {
                            error "Failed to find STORAGE_AWS_EXTERNAL_ID"
                        }

                        echo "Storage IAM User ARN: ${STORAGE_AWS_IAM_USER_ARN}"
                        echo "Storage External ID: ${STORAGE_AWS_EXTERNAL_ID}"
                    }
                }
            }
        }

        stage('Update Trust Relationship in IAM Role') {
            steps {
                script {
                    withAWS(credentials: 'aws_credentials') {
                        def roleName = "snowflake-role"
                        def trustPolicy = """
                        {
                            "Version": "2012-10-17",
                            "Statement": [
                                {
                                    "Effect": "Allow",
                                    "Principal": {
                                        "AWS": "${STORAGE_AWS_IAM_USER_ARN}"
                                    },
                                    "Action": "sts:AssumeRole",
                                    "Condition": {
                                        "StringEquals": {
                                            "sts:ExternalId": "${STORAGE_AWS_EXTERNAL_ID}"
                                        }
                                    }
                                }
                            ]
                        }
                        """

                        sh "aws iam update-assume-role-policy --role-name ${roleName} --policy-document '${trustPolicy}'"

                        echo "Trust relationship updated for IAM Role '${roleName}'."
                    }
                }
            }
        }
    }
}
