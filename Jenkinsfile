pipeline {
    agent any

    environment {
        def snowflake_user = env.SNOWFLAKE_USER
        def snowflake_password = env.SNOWFLAKE_PASSWORD
        SNOWFLAKE_ACCOUNT = 'kx23846.ap-southeast-1'
        SNOWFLAKE_DATABASE = 'dev_convertr'
        SNOWFLAKE_SCHEMA = 'stage'
        STAGE_NAME = 's3_stage'
        TABLE_NAME = 'stg_campaign1'
        S3_BUCKET = 'snowflake-input11'
    }

    stages {
        stage('Create Snowflake File Format') {
            steps {
                script {
                    snowflakeQuery("CREATE OR REPLACE FILE FORMAT my_csv_format
                        TYPE = CSV FIELD_DELIMITER = ',' SKIP_HEADER = 1
                        FIELD_OPTIONALLY_ENCLOSED_BY = '\"'
                        NULL_IF = ('NULL', 'null')
                        EMPTY_FIELD_AS_NULL = TRUE
                        ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;")
                }
            }
        }

        stage('Create Snowflake Stage') {
            steps {
                script {
                    snowflakeQuery("CREATE OR REPLACE STAGE ${env.SNOWFLAKE_SCHEMA}.${env.STAGE_NAME} URL='s3://${env.S3_BUCKET}'
                        STORAGE_INTEGRATION = s3_int
                        FILE_FORMAT = dev_convertr.stage.my_file_format;")
                }
            }
        }

        stage('Run COPY Command') {
            steps {
                script {
                    snowflakeQuery("COPY INTO ${env.SNOWFLAKE_SCHEMA}.${env.TABLE_NAME}
                        FROM (SELECT \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12,\$13,\$14,\$15,\$16,\$17,\$18,\$19,\$20,
                        METADATA\$FILENAME, CURRENT_TIMESTAMP(), 'Not Processed', NULL
                        FROM @${env.STAGE_NAME})
                        PATTERN='.*Campaign1.*[.]csv';")
                }
            }
        }
    }
}

def snowflakeQuery(query) {
    sh """
    snowsql -u ${env.SNOWFLAKE_USER} -p ${env.SNOWFLAKE_PASSWORD} -a ${env.SNOWFLAKE_ACCOUNT} -d ${env.SNOWFLAKE_DATABASE} -s ${env.SNOWFLAKE_SCHEMA} -q \"${query}\"
    """
}
