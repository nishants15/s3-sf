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
                        script: 'sudo -u ec2-user snowsql -c my_connection -q "DESC INTEGRATION s3_integration"'
                    ).trim()

                    echo "Integration Details:"
                    echo integrationDetails

                    def awsRoleArnValue = extractValue(integrationDetails, 'STORAGE_AWS_ROLE_ARN')
                    def externalIdValue = extractValue(integrationDetails, 'STORAGE_AWS_EXTERNAL_ID', '=')
                    def iamUserArnValue = extractValue(integrationDetails, 'STORAGE_AWS_IAM_USER_ARN')

                    if (awsRoleArnValue && externalIdValue && iamUserArnValue) {
                        updateAwsRoleTrustRelationship(awsRoleArnValue, externalIdValue, iamUserArnValue)
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

def extractValue(integrationDetails, propertyName, delimiter = '|') {
    def lines = integrationDetails.readLines()
    for (def line : lines) {
        def columns = line.trim().split('\\' + delimiter)
        if (columns.size() == 4 && columns[1].trim() == propertyName) {
            return columns[2].trim()
        }
    }
    return null
}

def updateAwsRoleTrustRelationship(awsRoleArn, externalId, iamUserArn) {
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
