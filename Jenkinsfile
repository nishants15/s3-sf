def snowflake_account = 'kx23846.ap-southeast-1'
def snowflake_user = 'mark'
def snowflake_password = 'Mark6789*'
def snowflake_warehouse = 'my_warehouse'
def snowflake_database = 'my_database'
def snowflake_schema = 'my_schema'
def s3_bucket_name = 'snowflake-input11'
def file_format_name = 'my_file_format'
def stage_name = 's3_stage'

pipeline {
  agent any

  environment {
    PATH = """$PATH:/root/bin"""
  }

  stages {
    stage('File Transfer') {
      steps {
        script {
          // Create the file format in Snowflake
          sh "snowsql -c connections.example -a ${snowflake_account} -u ${snowflake_user} -p ${snowflake_password} -w ${snowflake_warehouse} -d ${snowflake_database} -s ${snowflake_schema} -q \"CREATE FILE FORMAT ${file_format_name} TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1;\""

          // Create the stage in Snowflake
          sh "snowsql -c connections.example -a ${snowflake_account} -u ${snowflake_user} -p ${snowflake_password} -w ${snowflake_warehouse} -d ${snowflake_database} -s ${snowflake_schema} -q \"CREATE STAGE ${stage_name} URL = 's3://${s3_bucket_name}/';\""

          // Run the copy command to transfer data from S3 to Snowflake
          sh "snowsql -c connections.example -a ${snowflake_account} -u ${snowflake_user} -p ${snowflake_password} -w ${snowflake_warehouse} -d ${snowflake_database} -s ${snowflake_schema} -q \"COPY INTO my_table FROM @${stage_name} FILE_FORMAT = '${file_format_name}';\""
        }
      }
    }

    // Additional stages or steps can be added as needed
  }
}
