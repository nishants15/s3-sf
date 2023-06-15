pipeline {
    agent any

    stages {
        stage('Setup') {
            steps {
                // Install AWS CLI
                sh 'pip install awscli --upgrade --user'
            }
        }

        stage('Snowflake Import') {
            environment {
                SNOWFLAKE_ACCOUNT = 'kx23846.ap-southeast-1'
                SNOWFLAKE_USER = 'mark'
                SNOWFLAKE_PASSWORD = 'Mark6789*'
                SNOWFLAKE_DATABASE = 'dev_convertr'
                SNOWFLAKE_WAREHOUSE = 'comput_wh'
                SNOWFLAKE_SCHEMA = 'stage'
                SNOWFLAKE_STAGE = 's3_stage'
                FILE_FORMAT = 'csv_format'
                TABLE_NAME = 'stg_campaign1'
                AWS_ACCESS_KEY_ID = 'ASIA5CA4YRK65W4BWEDY'
                AWS_SECRET_ACCESS_KEY = 'c+ZHKYlJX8Z0bEj2biCiaHj+Ogl4ZtTAyKCrbiUg'
            }
            steps {
                script {
                    // Run queries before COPY command
                    sh """
                        snowsql -a ${SNOWFLAKE_ACCOUNT} -u ${SNOWFLAKE_USER} -p '${SNOWFLAKE_PASSWORD}' -c "USE ROLE ACCOUNTADMIN; USE DATABASE ${SNOWFLAKE_DATABASE}; USE SCHEMA ${SNOWFLAKE_SCHEMA};"
                    """

                    // Snowflake import query
                    def importQuery = """
                        COPY INTO ${TABLE_NAME}
                        FROM (SELECT \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12,\$13,\$14,\$15,\$16,\$17,\$18,\$19,\$20,METADATA\$FILENAME,current_timestamp(),'Not Processed', null
                        FROM @${SNOWFLAKE_STAGE})
                        PATTERN='.*Campaign1.*[.]csv'
                        FILE_FORMAT = ${FILE_FORMAT};
                    """

                    // Set AWS credentials as environment variables
                    env.AWS_ACCESS_KEY_ID = AWS_ACCESS_KEY_ID
                    env.AWS_SECRET_ACCESS_KEY = AWS_SECRET_ACCESS_KEY

                    // Run Snowflake import query
                    sh """
                        snowsql -a ${SNOWFLAKE_ACCOUNT} -u ${SNOWFLAKE_USER} -p '${SNOWFLAKE_PASSWORD}' -d ${SNOWFLAKE_DATABASE} -w ${SNOWFLAKE_WAREHOUSE} -s ${SNOWFLAKE_SCHEMA} -c "USE ROLE ACCOUNTADMIN; ${importQuery}"
                    """
                }
            }
        }
    }
}
