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
                sh "echo 'SNOWSQL_ACCOUNT=kx23846.ap-southeast-1' > snowsql_config"
                sh "echo 'SNOWSQL_USER=mark' >> snowsql_config"
                sh "echo 'SNOWSQL_PASSWORD=valid_password' >> snowsql_config"
                sh "echo 'SNOWSQL_ROLE=accountadmin' >> snowsql_config"
                sh "echo 'SNOWSQL_WAREHOUSE=compute_wh' >> snowsql_config"

                sh "~/bin/snowsql -c snowsql_config -f create_stage.sql"
            }
        }

        stage('Copy data from S3 to Snowflake') {
            steps {
                sh "~/bin/snowsql -c snowsql_config -f copy_data.sql"
            }
        }
    }
}
