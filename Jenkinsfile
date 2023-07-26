pipeline {
    agent any

    stages {
        stage('Create IAM Role') {
            steps {
                script {
                    withAWS(credentials: 'aws_credentials') {
                        def accountId = "988231236474"
                        def externalId = "0000"
                        def snowflakeUserArn = "arn:aws:iam::123456789001:user/abc1-b-self1234"
                        def snowflakeExternalId = "MYACCOUNT_SFCRole=2_a123456/s0aBCDEfGHIJklmNoPq="

                        def trustPolicy = """{
                            \"Version\": \"2012-10-17\",
                            \"Statement\": [
                                {
                                    \"Sid\": \"\",
                                    \"Effect\": \"Allow\",
                                    \"Principal\": {
                                        \"AWS\": \"${snowflakeUserArn}\"
                                    },
                                    \"Action\": \"sts:AssumeRole\",
                                    \"Condition\": {
                                        \"StringEquals\": {
                                            \"sts:ExternalId\": \"${snowflakeExternalId}\"
                                        }
                                    }
                                }
                            ]
                        }"""

                        def roleName = "snowflake-role"

                        def role = createRole(roleName, trustPolicy)
                        attachPolicyToRole(role, "snowpolicy")

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
                            script: "sudo -u ec2-user snowsql -c my_connection -q 'DESC INTEGRATION s3_integration;' | grep -E 'STORAGE_AWS_IAM_USER_ARN|STORAGE_AWS_EXTERNAL_ID'",
                            returnStdout: true
                        )

                        def storageIAMUserArn = integrationOutput.split("\n")[0].split("|")[2].trim()
                        def storageExternalId = integrationOutput.split("\n")[5].split("|")[2].trim()

                        echo "Storage IAM User ARN: ${storageIAMUserArn}"
                        echo "Storage External ID: ${storageExternalId}"
                    }
                }
            }
        }
        stage('Update Trust Relationship in IAM Role') {
            steps {
                script {
                    withAWS(credentials: 'aws_credentials') {
                        def roleName = "snowflake-role"
                        def trustPolicy = """{
                            \"Version\": \"2012-10-17\",
                            \"Statement\": [
                                {
                                    \"Sid\": \"\",
                                    \"Effect\": \"Allow\",
                                    \"Principal\": {
                                        \"AWS\": \"${storageIAMUserArn}\"
                                    },
                                    \"Action\": \"sts:AssumeRole\",
                                    \"Condition\": {
                                        \"StringEquals\": {
                                            \"sts:ExternalId\": \"${storageExternalId}\"
                                        }
                                    }
                                }
                            ]
                        }"""

                        def roleArn = awsiamGetRole(roleName: roleName).arn
                        def updatedTrustPolicy = updateTrustPolicyForRole(roleArn, trustPolicy)

                        echo "Updated trust policy for IAM role '${roleName}':"
                        echo updatedTrustPolicy
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                // Clean up resources, if needed.
            }
        }
    }
}

def createRole(roleName, trustPolicy) {
    def roleNameEncoded = roleName.replace(" ", "_").replaceAll("[^a-zA-Z0-9]", "")

    def roleArn = awsiamCreateRole(
        roleName: roleNameEncoded,
        assumeRolePolicyDocument: trustPolicy,
    ).arn

    return roleArn
}

def attachPolicyToRole(roleArn, policyName) {
    awsiamAttachRolePolicy(roleArn: roleArn, policyArn: "arn:aws:iam::988231236474:policy/${policyName}")
}

def updateTrustPolicyForRole(roleArn, trustPolicy) {
    def policyName = "AssumeRolePolicyDocument"
    def policyDoc = [
        roleName: roleArn,
        policyName: policyName,
        policyDocument: trustPolicy
    ]

    def updatedPolicyResponse = awsiamUpdateAssumeRolePolicy(policyDoc)
    def updatedTrustPolicy = updatedPolicyResponse.get('AssumeRolePolicyDocument')

    return updatedTrustPolicy
}
