pipeline {
    agent any
        environment {
            AWS_REGION = 'us-east-1'
            AWS_ACCESS_KEY_ID = credentials('aws_credentials')?.accessKeyId ?: ""
            AWS_SECRET_ACCESS_KEY = credentials('aws_credentials')?.secretAccessKey ?: ""
        }
        stage("Authenticate with Snowflake") {
            steps {
                sh 'echo "SNOWSQL_ACCOUNT=itb89569.us-east-1" > snowsql_config'
                sh 'echo "SNOWSQL_USER=mark" >> snowsql_config'
                sh "echo 'SNOWSQL_PASSWORD=${env.SNOWSQL_PASSWORD}' >> snowsql_config"
                sh 'echo "SNOWSQL_ROLE=accountadmin" >> snowsql_config'
                sh 'echo "SNOWSQL_WAREHOUSE=compute_wh" >> snowsql_config'
            }
        }

        stage('Connection establishment') {
            steps {
                // Use sudo with -E option to preserve environment variables
                sh "sudo -u ec2-user snowsql -c my_connection"
            }
        }

        stage('Create Snowflake Stage') {
            steps {
                // Use sudo with -E option to preserve environment variables
                sh """
                    sudo -u ec2-user snowsql -c my_connection -q \\
                    "create or replace stage dev_convertr.stage.s3_stage \\
                    url='s3://snowflake-input11' \\
                    STORAGE_INTEGRATION = s3_int \\
                    FILE_FORMAT = dev_convertr.stage.my_file_format"
                """
            }
        }

        stage('Run SQL Script') {
            steps {
                sh 'sudo -u ec2-user snowsql -c my_connection -f copy_data.sql'
            }
        }
    }
}
