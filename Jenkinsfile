pipeline {
    agent any
    
    stages {
        stage('AWS Configuration') {
            steps {
                script {
                    def roleName = 'snowflake-role'
                    def externalId = '0000000'
                    def accountId = '988231236474'
                    
                    withAWS(credentials: 'aws_credentials') {
                        def createRoleCommand = "aws iam create-role --role-name ${roleName} --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"${accountId}\"},\"Action\":\"sts:AssumeRole\",\"Condition\":{\"StringEquals\":{\"sts:ExternalId\":\"${externalId}\"}}}]}')"
                        sh createRoleCommand
                        
                        def putRolePolicyCommand = "aws iam put-role-policy --role-name ${roleName} --policy-name s3-access-policy --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:ListBucket\"],\"Resource\":\"arn:aws:s3:::snowflake-input12\"},{\"Effect\":\"Allow\",\"Action\":[\"s3:GetObject\",\"s3:PutObject\"],\"Resource\":\"arn:aws:s3:::snowflake-input12/*\"}]}'"
                        sh putRolePolicyCommand
                        
                        def getRoleCommand = "aws iam get-role --role-name ${roleName} --query 'Role.Arn' --output text"
                        def roleArn = sh(script: getRoleCommand, returnStdout: true).trim()
                        echo "Role ARN: ${roleArn}"
                        
                        def updateAssumeRolePolicyCommand = "aws iam update-assume-role-policy --role-name ${roleName} --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"<snowflake-iam-user-arn>\"},\"Action\":\"sts:AssumeRole\",\"Condition\":{\"StringEquals\":{\"sts:ExternalId\":\"<snowflake-aws-external-id>\"}}}]}'"
                        updateAssumeRolePolicyCommand = updateAssumeRolePolicyCommand.replace('<snowflake-iam-user-arn>', '<replace-with-snowflake-iam-user-arn>').replace('<snowflake-aws-external-id>', '<replace-with-snowflake-aws-external-id>')
                        sh updateAssumeRolePolicyCommand
                    }
                }
            }
        }
        
        stage('Snowflake Configuration') {
            steps {
                sh 'sudo -u ec2-user snowsql -c my_connection -q "create or replace storage integration s3_integration in snowflake using role_arn=\'<role-arn>\' aws_external_id=\'<aws-external-id>\' storage_provider=s3 storage_allowed_locations = (\'s3://snowflake-input12\')"'
                sh 'sudo -u ec2-user snowsql -c my_connection -q "desc s3_integration"'
                sh 'aws iam update-assume-role-policy --role-name snowflake-role --policy-document \'{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"<snowflake-iam-user-arn>"},"Action":"sts:AssumeRole","Condition":{"StringEquals":{"sts:ExternalId":"<snowflake-aws-external-id>"}}}]}\''
            }
        }
        
        stage('File Format and Stage Creation') {
            steps {
                sh 'sudo -u ec2-user snowsql -c my_connection -q "create or replace file format csv_format type=\'CSV\' field_delimiter=\',\' skip_header=1;"'
                sh 'sudo -u ec2-user snowsql -c my_connection -q "create or replace stage my_stage storage_integration=s3_integration url=\'s3://snowflake-input12\' file_format=csv_format"'
            }
        }
    }
}
