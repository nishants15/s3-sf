pipeline {
    agent any
    
    stages {
        stage('Create AWS Role') {
            steps {
                withAWS(credentials: awsCredentialsId) {
                    sh '''
                    aws iam create-role --role-name snowflake-role --assume-role-policy-document '{
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
                                        "sts:ExternalId": "0000000"
                                    }
                                }
                            }
                        ]
                    }' --account-id 988231236474 --permissions-boundary arn:aws:iam::988231236474:policy/ReadOnlyAccess
                    '''
                }
            }
        }
        
        stage('Create Snowflake Storage Integration') {
            steps {
                sh '''
                sudo -u ec2-user snowsql -c my_connection -q "create or replace storage integration s3_integration with aws_role_arn='arn:aws:iam::988231236474:role/snowflake-role' and s3_uri='s3://snowflake-input12'"
                '''
            }
        }
        
        stage('Fetch Storage AWS IAM User ARN and External ID') {
            steps {
                sh '''
                sudo -u ec2-user snowsql -c my_connection -q "desc s3_integration"
                '''
            }
        }
        
        stage('Update AWS Role Trust Relationship') {
            steps {
                withAWS(credentials: awsCredentialsId) {
                    sh '''
                    aws iam update-assume-role-policy --role-name snowflake-role --policy-document file://trust-relationship.json
                    '''
                }
            }
        }
        
        stage('Create CSV File Format') {
            steps {
                sh '''
                sudo -u ec2-user snowsql -c my_connection -q "create file format csv with delimiter=','"
                '''
            }
        }
        
        stage('Create Snowflake Stage') {
            steps {
                sh '''
                sudo -u ec2-user snowsql -c my_connection -q "create stage snowflake-input12 with storage_integration='s3_integration' and s3_url='s3://snowflake-input12' and file_format='csv'"
                '''
            }
        }
    }
}
