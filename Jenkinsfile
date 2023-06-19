pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                // Clone the GitHub repository
                git branch: 'int', credentialsId: 'GH-credentials', url: 'https://github.com/nishants15/s3-sf.git'
            }
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
                sh 'cat snowsql_config' // Print the content of the snowsql_config file
                sh "root/bin/snowsql -v 1.2.27 -c my_connection"
            }
        }

        stage('Create Snowflake Stage') {
            steps {
                // Use sudo with -E option to preserve environment variables
                sh """
                    root/bin/snowsql -v 1.2.27 -c my_connection -q \\
                    "create or replace stage dev_convertr.stage.s3_stage \\
                    url='s3://snowflake-input11' \\
                    STORAGE_INTEGRATION = s3_int \\
                    FILE_FORMAT = dev_convertr.stage.my_file_format"
                """
            }
        }
    }
}
