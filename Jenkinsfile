pipeline {
    agent any
    stages {
        stage('Deployment') {
            steps {
                script {
                    stage('Create AWS Role') {
                        def trust_policy_document = '''
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
                        trust_policy_document = trust_policy_document.strip()

                        withAWS(credentials: 'aws_credentials') {
                            writeFile file: 'trust-policy.json', text: trust_policy_document
                            sh 'aws iam create-role --role-name snowflake-role --assume-role-policy-document file://trust-policy.json'
                        }
                    }

                    stage('Create Snowflake Storage Integration') {
                        sh '''
                        sudo -u ec2-user snowsql -c my_connection -q "create or replace storage integration s3_integration
                            TYPE = EXTERNAL_STAGE
                            STORAGE_PROVIDER = S3
                            ENABLED = TRUE 
                            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::988231236474:role/snowflake-role'
                            STORAGE_ALLOWED_LOCATIONS = ('s3://snowflake-input12')"
                        '''
                    }

                   stage('Fetch AWS IAM User ARN and External ID from Snowflake') {
            steps {
                script {
                    def storageAwsIamUserArn = sh(
                        returnStdout: true,
                        script: "sudo -u ec2-user snowsql -c my_connection -q 'DESC INTEGRATION s3_integration' | grep 'STORAGE_AWS_IAM_USER_ARN' | awk -F'|' '{print \$3}' | tr -d '[:space:]'"
                    ).trim()

                    def storageAwsExternalId = sh(
                        returnStdout: true,
                        script: "sudo -u ec2-user snowsql -c my_connection -q 'DESC INTEGRATION s3_integration' | grep 'STORAGE_AWS_EXTERNAL_ID' | awk -F'|' '{print \$3}' | tr -d '[:space:]'"
                    ).trim()
                    
                    // Store the fetched values as environment variables for later use
                    env.STORAGE_AWS_IAM_USER_ARN = storageAwsIamUserArn
                    env.STORAGE_AWS_EXTERNAL_ID = storageAwsExternalId
                }
            }
        }
        
        stage('Update AWS IAM Role Trust Relationship') {
            steps {
                script {
                    def trustPolicyDocument = '''
                    {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Effect": "Allow",
                                "Principal": {
                                    "AWS": "${env.STORAGE_AWS_IAM_USER_ARN}"
                                },
                                "Action": "sts:AssumeRole",
                                "Condition": {
                                    "StringEquals": {
                                        "sts:ExternalId": "${env.STORAGE_AWS_EXTERNAL_ID}"
                                    }
                                }
                            }
                        ]
                    }
                    '''
                    trustPolicyDocument = trustPolicyDocument.strip()
                    
                    withAWS(credentials: 'aws_credentials') {
                        writeFile file: 'trust-policy.json', text: trustPolicyDocument
                        sh 'aws iam update-assume-role-policy --role-name snowflake-role --policy-document file://trust-policy.json'
                    }
                }
            }
        }
    }
}k
