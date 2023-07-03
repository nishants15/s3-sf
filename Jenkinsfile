pipeline {
    agent any
    stages {
        stage('Create AWS Role') {
    steps {
        script {
            def trust_policy_document = '''
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": {
                    "Account": "988231236474"
                }
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "0000000"
                }
            }
        }
    ]
}
'''
            withAWS(credentials: 'aws_credentials') {
                sh """
echo '${trust_policy_document}' > trust-policy.json
aws iam create-role --role-name snowflake-role --assume-role-policy-document file://trust-policy.json --permissions-boundary arn:aws:iam::988231236474:policy/ReadOnlyAccess
"""
            }
        }
    }
}
        stage('Create Snowflake Storage Integration') {
            steps {
                sh '''
sudo -u ec2-user snowsql -c my_connection
create or replace storage integration s3_integration with aws_role_arn="arn:aws:iam::988231236474:role/snowflake-role" and s3_uri="s3://snowflake-input12"
'''
            }
        }
        
        stage('Fetch Storage AWS IAM User ARN and External ID') {
            steps {
                sh '''
sudo -u ec2-user snowsql -c my_connection
desc s3_integration
'''
            }
        }
        
        stage('Update AWS Role Trust Relationship') {
            steps {
                withAWS(credentials: 'aws_credentials') {
                    sh '''
aws iam update-assume-role-policy --role-name snowflake-role --policy-document file://trust-policy.json
'''
                }
            }
        }
        
        stage('Create CSV File Format') {
            steps {
                sh '''
sudo -u ec2-user snowsql -c my_connection
create file format csv with delimiter=','
'''
            }
        }
        
        stage('Create Snowflake Stage') {
            steps {
                sh '''
sudo -u ec2-user snowsql -c my_connection
create stage snowflake-input12 with storage_integration='s3_integration' and s3_uri="s3://snowflake-input12" and file_format='csv'
'''
            }
        }
    }
}
