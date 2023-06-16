pipeline {
    agent any

    environment {
        SNOWFLAKE_USER = env.SNOWFLAKE_USER
        SNOWFLAKE_PASSWORD = env.SNOWFLAKE_PASSWORD
        SNOWFLAKE_ACCOUNT = 'kx23846.ap-southeast-1'
        SNOWFLAKE_DATABASE = 'dev_convertr'
        SNOWFLAKE_SCHEMA = 'stage'
        S3_BUCKET_NAME = 'snowflake-input11'
        FILE_FORMAT_NAME = 'my_file_format'
        STAGE_NAME = 's3_stage'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'int', credentialsId: 'GH-credentials', url: 'https://github.com/nishants15/s3-sf.git'
            }
        }

        stage('Transfer Data to Snowflake') {
            steps {
                script {
                    // Install SnowSQL (Snowflake CLI)
                    sh 'sudo curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.2/linux_x86_64/snowsql-1.2.6-linux_x86_64.bash'
                    sh 'sudo chmod +x snowsql-1.2.6-linux_x86_64.bash'
                    sh 'sudo ./snowsql-1.2.6-linux_x86_64.bash -e'

                    // Create Snowflake stage
                    sh "snowsql -u ${env.SNOWFLAKE_USER} -p ${env.SNOWFLAKE_PASSWORD} -a ${env.SNOWFLAKE_ACCOUNT} -d ${env.SNOWFLAKE_DATABASE} -s ${env.SNOWFLAKE_SCHEMA} -w <your_warehouse> -q \"CREATE OR REPLACE STAGE ${env.STAGE_NAME} URL = 's3://${env.S3_BUCKET_NAME}' FILE_FORMAT = (FORMAT_NAME = '${env.FILE_FORMAT_NAME}')\""

                    // Run COPY command
                    sh "snowsql -u ${env.SNOWFLAKE_USER} -p ${env.SNOWFLAKE_PASSWORD} -a ${env.SNOWFLAKE_ACCOUNT} -d ${env.SNOWFLAKE_DATABASE} -s ${env.SNOWFLAKE_SCHEMA} -w <your_warehouse> -q \"COPY INTO <target_table> FROM @${env.STAGE_NAME} FILE_FORMAT = (FORMAT_NAME = '${env.FILE_FORMAT_NAME}')\""
                }
            }
        }
    }
}
