pipeline {
    agent any

    environment {
        SNOWFLAKE_USER = 'mark'
        SNOWFLAKE_PASSWORD = 'Mark6789*'
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
                    // Download SnowSQL binary zip
                    sh 'wget https://snowflake-snowsql-1.2.27-1.x86_64.rpm.zip'

                    // Install SnowSQL (Snowflake CLI)
                    sh 'unzip snowsql-1.2.27-linux_x86_64.zip'
                    sh 'sudo ./snowsql-*/snowsql -e'

                    // Create Snowflake stage
                    sh "sudo ./snowsql-*/snowsql -u ${env.SNOWFLAKE_USER} -p ${env.SNOWFLAKE_PASSWORD} -a ${env.SNOWFLAKE_ACCOUNT} -d ${env.SNOWFLAKE_DATABASE} -s ${env.SNOWFLAKE_SCHEMA} -w compute_wh -q \"CREATE OR REPLACE STAGE ${env.STAGE_NAME} URL = 's3://${env.S3_BUCKET_NAME}' FILE_FORMAT = (FORMAT_NAME = '${env.FILE_FORMAT_NAME}')\""

                    // Run COPY command
                    sh "sudo ./snowsql-*/snowsql -u ${env.SNOWFLAKE_USER} -p ${env.SNOWFLAKE_PASSWORD} -a ${env.SNOWFLAKE_ACCOUNT} -d ${env.SNOWFLAKE_DATABASE} -s ${env.SNOWFLAKE_SCHEMA} -w compute_wh -q \"COPY INTO stg_campaign1 FROM @${env.STAGE_NAME} FILE_FORMAT = (FORMAT_NAME = '${env.FILE_FORMAT_NAME}')\""
                }
            }
        }
    }
}