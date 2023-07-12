pipeline {
    agent any
    stages {
            stage('Create AWS Role') {
            steps {
                withAWS(credentials: 'aws_credentials') {
                    script {
                        def trustPolicyDocument = '''
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
                        '''
                        trustPolicyDocument = trustPolicyDocument.strip()

                        // Create the trust-policy.json file in the /home/ec2 directory with sudo
                        writeFile file: '/home/ec2/trust-policy.json', text: trustPolicyDocument, using: 'sudo'
                        sh 'sudo aws iam create-role --role-name snowflake-role --assume-role-policy-document file:///home/ec2/trust-policy.json'
                    }
                }
            }
        }

        stage('Create Snowflake Storage Integration') {
            steps {
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

       stage('Fetch AWS IAM User ARN and External ID from Snowflake') {
                    steps {
                        script {
                            def storageAwsIamUserArn = sh(
                                returnStdout: true,
                                script: 'export STORAGE_AWS_IAM_USER_ARN=\\"$(sudo -u ec2-user snowsql -c my_connection -q \'DESC INTEGRATION s3_integration\' | grep \'STORAGE_AWS_IAM_USER_ARN\' | awk -F\'|\' \'{print \$3}\' | tr -d \'[:space:]\')\\" && echo \$STORAGE_AWS_IAM_USER_ARN'
                            ).trim()

                            def storageAwsExternalId = sh(
                                returnStdout: true,
                                script: 'export STORAGE_AWS_EXTERNAL_ID=\\"$(sudo -u ec2-user snowsql -c my_connection -q \'DESC INTEGRATION s3_integration\' | grep \'STORAGE_AWS_EXTERNAL_ID\' | awk -F\'|\' \'{print \$3}\' | tr -d \'[:space:]\')\\" && echo \$STORAGE_AWS_EXTERNAL_ID'
                            ).trim()

                            // Store the fetched values as environment variables for later use
                            env.STORAGE_AWS_IAM_USER_ARN = storageAwsIamUserArn
                            env.STORAGE_AWS_EXTERNAL_ID = storageAwsExternalId
                        }
                    }
                }


                    stage('Update AWS IAM Role Trust Relationship') {
            steps {
                withAWS(credentials: 'aws_credentials') {
                    script {
                        // Read the trust-policy.json file from the /home/ec2 directory with sudo
                        def trustPolicyDocument = readFile file: '/home/ec2/trust-policy.json', using: 'sudo'

                        writeFile file: '/home/ec2/trust-policy.json', text: trustPolicyDocument, using: 'sudo'
                        sh 'sudo aws iam update-assume-role-policy --role-name snowflake-role --policy-document file:///home/ec2/trust-policy.json'
                    }
                }
            }
        }
    }
}