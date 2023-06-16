pipeline {
  agent any

  environment {
    SNOWSQL_DIRECTORY = '/home/jenkins/snowsql'
    PATH = "${SNOWSQL_DIRECTORY}:${env.PATH}"
  }

  stages {
    stage('Prepare Environment') {
      steps {
        script {
          def snowflake_user = env.SNOWFLAKE_USER
          def snowflake_password = env.SNOWFLAKE_PASSWORD
          def snowflake_account = 'kx23846.ap-southeast-1'
          def snowflake_database = 'dev_convertr'
          def snowflake_schema = 'stage'
          def s3_bucket_name = 'snowflake-input11'
          def file_format_name = 'my_file_format'
          def stage_name = 's3_stage'

          // Download snowsql
          sh "mkdir -p ${SNOWSQL_DIRECTORY}"
          sh "curl -o ${SNOWSQL_DIRECTORY}/snowsql https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.2/linux_x86_64/snowsql-1.2.16-linux_x86_64.bash"
          sh "chmod +x ${SNOWSQL_DIRECTORY}/snowsql"

          // Run the Snowflake commands using snowsql
          sh "snowsql -c connections.example -a ${snowflake_account} -u ${snowflake_user} -p ${snowflake_password} -w ${snowflake_warehouse} -d ${snowflake_database} -s ${snowflake_schema} -q \"CREATE FILE FORMAT ${file_format_name} TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1;\""
          sh "snowsql -c connections.example -a ${snowflake_account} -u ${snowflake_user} -p ${snowflake_password} -w ${snowflake_warehouse} -d ${snowflake_database} -s ${snowflake_schema} -q \"CREATE STAGE ${stage_name} URL = 's3://${s3_bucket_name}/';\""
          sh "snowsql -c connections.example -a ${snowflake_account} -u ${snowflake_user} -p ${snowflake_password} -w ${snowflake_warehouse} -d ${snowflake_database} -s ${snowflake_schema} -q \"COPY INTO my_table FROM @${stage_name} FILE_FORMAT = '${file_format_name}';\""
        }
      }
    }

    // Additional stages or steps can be added as needed
  }
}
