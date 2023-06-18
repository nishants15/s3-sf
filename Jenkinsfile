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
                sh 'echo "SNOWSQL_ACCOUNT=kx23846.ap-southeast-1" > snowsql_config'
                sh 'echo "SNOWSQL_USER=mark" >> snowsql_config'
                sh "echo 'SNOWSQL_PASSWORD=${env.snowflake_password}' >> snowsql_config"
                sh 'echo "SNOWSQL_ROLE=accountadmin" >> snowsql_config'
                sh 'echo "SNOWSQL_WAREHOUSE=compute_wh" >> snowsql_config'

                // Adjust ownership and permissions
                sh 'sudo chown -R ec2-user:ec2-user /home/snowsql_rt.log_bootstrap'
                sh 'sudo chmod +w /home/snowsql_rt.log_bootstrap'

                // Use sudo with -E option to preserve environment variables
                sh 'sudo -E snowsql -c snowsql_config -f create_stage.sql'
            }
        }

        stage('Copy data from S3 to Snowflake') {
            steps {
                // Use sudo with -E option to preserve environment variables
                sh 'sudo -E snowsql -c snowsql_config -f copy_data.sql'
            }
        }
    }
}
