pipeline {
    agent any

    environment {
        SNOWFLAKE_USER = 'mark'
        SNOWFLAKE_PASSWORD = 'Mark6789*'
        SNOWFLAKE_ACCOUNT = 'kx23846.ap-southeast-1'
        SNOWFLAKE_DATABASE = 'dev_convertr'
        SNOWFLAKE_SCHEMA = 'stage'
        STAGE_NAME = 's3_stage'
        TABLE_NAME = 'stg_campaign1'
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout the Jenkinsfile from the Git repository
                checkout([$class: 'GitSCM', branches: [[name: 'int']], userRemoteConfigs: [[url: 'https://github.com/nishants15/s3-sf.git']], credentialsId: 'GH-credentials'])
            }
        }

        stage('Create or Replace File Format') {
            steps {
                script {
                    def query = "CREATE OR REPLACE FILE FORMAT my_csv_format " +
                                "TYPE = CSV FIELD_DELIMITER = ',' SKIP_HEADER = 1 " +
                                "FIELD_OPTIONALLY_ENCLOSED_BY = '\"' NULL_IF = ('NULL', 'null') " +
                                "EMPTY_FIELD_AS_NULL = TRUE " +
                                "ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE"

                    sh "snowsql -u ${env.SNOWFLAKE_USER} -p ${env.SNOWFLAKE_PASSWORD} -a ${env.SNOWFLAKE_ACCOUNT} -d ${env.SNOWFLAKE_DATABASE} -s ${env.SNOWFLAKE_SCHEMA} -q \"${query}\""
                }
            }
        }

        stage('Create or Replace Stage') {
            steps {
                script {
                    def query = "CREATE OR REPLACE STAGE ${env.SNOWFLAKE_SCHEMA}.${env.STAGE_NAME} " +
                                "URL = 's3://snowflake-input11' " +
                                "STORAGE_INTEGRATION = s3_int " +
                                "FILE_FORMAT = dev_convertr.stage.my_csv_format"

                    sh "snowsql -u ${env.SNOWFLAKE_USER} -p ${env.SNOWFLAKE_PASSWORD} -a ${env.SNOWFLAKE_ACCOUNT} -d ${env.SNOWFLAKE_DATABASE} -s ${env.SNOWFLAKE_SCHEMA} -q \"${query}\""
                }
            }
        }

        stage('Run COPY Command') {
            steps {
                script {
                    def query = "COPY INTO ${env.SNOWFLAKE_SCHEMA}.${env.TABLE_NAME} " +
                                "FROM (SELECT \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12,\$13,\$14,\$15,\$16,\$17,\$18,\$19,\$20, " +
                                "METADATA\$FILENAME, CURRENT_TIMESTAMP(), 'Not Processed', NULL " +
                                "FROM @${env.STAGE_NAME}) " +
                                "PATTERN = '.*Campaign1.*[.]csv'"

                    sh "snowsql -u ${env.SNOWFLAKE_USER} -p ${env.SNOWFLAKE_PASSWORD} -a ${env.SNOWFLAKE_ACCOUNT} -d ${env.SNOWFLAKE_DATABASE} -s ${env.SNOWFLAKE_SCHEMA} -q \"${query}\""
                }
            }
        }
    }
}
