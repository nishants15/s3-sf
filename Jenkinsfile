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
                sh 'echo "SNOWSQL_ACCOUNT=itb89569.ap-southeast-1" > snowsql_config'
                sh 'echo "SNOWSQL_USER=mark" >> snowsql_config'
                sh "echo 'SNOWSQL_PASSWORD=${env.SNOWSQL_PASSWORD}' >> snowsql_config"
                sh 'echo "SNOWSQL_ROLE=accountadmin" >> snowsql_config'
                sh 'echo "SNOWSQL_WAREHOUSE=compute_wh" >> snowsql_config'

                // Use sudo with -E option to preserve environment variables
                sh "snowsql -c my_connection -f create_stage.sql"

            }
        }

        stage('Copy data from S3 to Snowflake') {
            steps {
                // Use sudo with -E option to preserve environment variables
                sh "snowsql -c my_connection -f copy_data.sql"
            }
        }
    }
}
