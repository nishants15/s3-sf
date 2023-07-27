pipeline {
    agent any

    environment {
        ROLE_NAME = "snowflake-role-new"
        STORAGE_AWS_IAM_USER_ARN = ""  // Declare the variable here
        STORAGE_AWS_EXTERNAL_ID = ""   // Declare the variable here
    }

    stages {
        stage('Create IAM Role') {
            steps {
                script {
                    def trustPolicy = """
                    {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Effect": "Allow",
                                "Principal": {
                                    "AWS": "<STORAGE_AWS_IAM_USER_ARN>"
                                },
                                "Action": "sts:AssumeRole",
                                "Condition": {
                                    "StringEquals": {
                                        "sts:ExternalId": "<STORAGE_AWS_EXTERNAL_ID>"
                                    }
                                }
                            }
                        ]
                    }
                    """

                    def roleName = "${ROLE_NAME}"

                    // Create the IAM Role
                    withAWS(credentials: 'aws_credentials') {
                        sh "aws iam create-role --role-name ${roleName} --assume-role-policy-document '${trustPolicy}'"
                    }

                    echo "IAM Role '${roleName}' with trust policy created successfully."
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
                            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::988231236474:role/snowflake-role-new'
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
                        def trustPolicy = readFile('trust-policy.json')
                        def roleName = "${ROLE_NAME}"

                        // Update the trust policy of the IAM role
                        trustPolicy = trustPolicy.replace("<STORAGE_AWS_IAM_USER_ARN>", "${STORAGE_AWS_IAM_USER_ARN}")
                        trustPolicy = trustPolicy.replace("<STORAGE_AWS_EXTERNAL_ID>", "${STORAGE_AWS_EXTERNAL_ID}")

                        sh "aws iam update-assume-role-policy --role-name ${roleName} --policy-document '${trustPolicy}'"

                        echo "Trust relationship updated for IAM Role '${roleName}'."
                    }
                }
            }
        }
    }
}
