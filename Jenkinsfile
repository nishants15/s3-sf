pipeline {
    agent any
    stages {
        stage('Create AWS Role') {
            steps {
                script {
                    def trust_policy_document = """
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
"""

                    trust_policy_document = trust_policy_document.strip()

                    withAWS(credentials: 'aws_credentials') {
                        writeFile file: 'trust-policy.json', text: trust_policy_document
                        sh 'aws iam create-role --role-name snowflake-role --assume-role-policy-document file://trust-policy.json'
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

        stage('Fetch Storage AWS IAM User ARN and External ID') {
            steps {
                script {
                    def integrationDetails = sh(
                        returnStdout: true,
                        script: 'sudo -u ec2-user snowsql -c my_connection -q "DESC INTEGRATION s3_integration" 2>&1 | grep -E "STORAGE_AWS_ROLE_ARN|STORAGE_AWS_EXTERNAL_ID"'
                    ).trim()

                    echo "Integration Details:"
                    echo integrationDetails

                    def awsRoleArn = integrationDetails =~ /STORAGE_AWS_ROLE_ARN\s+\|\s+([^\n]+)/
                    def externalId = integrationDetails =~ /STORAGE_AWS_EXTERNAL_ID\s+\|\s+([^\n]+)/

                    if (awsRoleArn && externalId) {
                        def awsRoleArnValue = awsRoleArn[0][1].trim()
                        def externalIdValue = externalId[0][1].trim()
                        updateAwsRoleTrustRelationship(awsRoleArnValue, externalIdValue)
                    } else {
                        error "Failed to retrieve Storage AWS IAM User ARN and External ID"
                    }
                }
            }
        }

        stage('Create Stage in Snowflake Account Using Storage Int and S3 URL') {
            steps {
                sh '''
                sudo -u ec2-user snowsql -c my_connection -q "create or replace stage dev_convertr.stage.s3_stage url='s3://snowflake-input12'
                    STORAGE_INTEGRATION = s3_integration
                    FILE_FORMAT = dev_convertr.stage.my_file_format"
                '''
            }
        }
    }
}

def updateAwsRoleTrustRelationship(awsRoleArn, externalId) {
    script {
        def trust_policy_document = """
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "${awsRoleArn}"
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
"""

        trust_policy_document = trust_policy_document.trim()

        writeFile file: 'trust-policy.json', text: trust_policy_document

        sh 'aws iam update-assume-role-policy --role-name snowflake-role --policy-document file://trust-policy.json'
    }
}
