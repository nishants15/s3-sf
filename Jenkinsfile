pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        // Clone the GitHub repository
        git branch: 'int', credentialsId: 'GH-credentials', url: 'https://github.com/nishants15/s3-sf.git'
      }
    }

    stage('Setup Snowflake Stage') {
      steps {
        script {
          def snowflake_user = 'mark'
          def snowflake_password = 'Mark6789*'
          def snowflake_account = 'kx23846.ap-southeast-1'
          def snowflake_database = 'dev_convertr'
          def snowflake_schema = 'stage'
          def s3_bucket_name = 'snowflake-input11'
          def file_format_name = 'my_file_format'
          def stage_name = 's3_stage'
          
          // Set AWS credentials using environment variables or AWS CLI configuration
          env.AWS_ACCESS_KEY_ID = credentials('aws-credentials').accessKeyId
          env.AWS_SECRET_ACCESS_KEY = credentials('aws-credentials').secretAccessKey
          env.AWS_DEFAULT_REGION = 'ap-southeast-1'

          // Download the Snowflake CLI
          sh "curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/2.13/linux_x86_64/snowsql-2.13.0-linux_x86_64.tar.gz"
          sh "tar -xzf snowsql-2.13.0-linux_x86_64.tar.gz"

          // Configure Snowflake CLI with credentials
          sh "echo -e \"account = '${snowflake_account}'\nusername = '${snowflake_user}'\npassword = '${snowflake_password}'\" > ~/.snowsql/config
          sh "./snowsql-2.13.0-linux_x86_64/snowsql -a ${snowflake_account} -u ${snowflake_user} -w ${snowflake_database} -s ${snowflake_schema} -r ci-cd-setup -d ${snowflake_database} -q 'USE WAREHOUSE COMPUT_WH'"

          // Create the Snowflake stage pointing to S3 bucket
          sh "./snowsql-2.13.0-linux_x86_64/snowsql -c ci-cd-setup -f -q \"CREATE STAGE ${stage_name} URL='s3://${s3_bucket_name}' FILE_FORMAT = (FORMAT_NAME = '${file_format_name}')\""
        }
      }
    }

    stage('Transfer CSV to Snowflake') {
      steps {
        script {
          def snowflake_user = 'mark'
          def snowflake_password = 'Mark6789*'
          def snowflake_account = 'kx23846.ap-southeast-1'
          def snowflake_database = 'dev_convertr'
          def snowflake_schema = 'stage'
          def stage_name = 's3_stage'
          def table_name = 'stg_campaign1'

          // Download the Snowflake JDBC driver
          def snowflakeJdbcUrl = 'https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/3.15.1/snowflake-jdbc-3.15.1.jar'
          sh "sudo mkdir -p /opt/"
          sh "sudo curl -L ${snowflakeJdbcUrl} -o /opt/snowflake-jdbc.jar"

          // Set up Snowflake JDBC connection properties
          def jdbcUrl = "jdbc:snowflake://${snowflake_account}/?user=${snowflake_user}&password=${snowflake_password}"
          def driverPath = '/opt/snowflake-jdbc.jar'
          def driverClass = 'net.snowflake.client.jdbc.SnowflakeDriver'

          // Snowflake COPY command
          def copyCommand = """
            COPY INTO ${snowflake_schema}.${table_name}
            FROM (SELECT \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12,\$13,\$14,\$15,\$16,\$17,\$18,\$19,\$20,
              METADATA\$FILENAME, CURRENT_TIMESTAMP(), 'Not Processed', NULL
              FROM @${stage_name})
            PATTERN='.*Campaign1.*[.]csv';
          """

          // Execute the COPY command using Snowflake JDBC driver
          sqlExecute(jdbcUrl, driverClass, driverPath, copyCommand)
        }
      }
    }
  }
}

import java.sql.DriverManager

def sqlExecute(jdbcUrl, driverClass, driverPath, query) {
  // Add Snowflake JDBC driver to classpath
  def loader = new URLClassLoader([new URL("file:${driverPath}")], this.getClass().getClassLoader())
  def driver = loader.loadClass(driverClass)
  DriverManager.registerDriver(driver.newInstance())

  def connection = DriverManager.getConnection(jdbcUrl)
  def statement = connection.createStatement()

  try {
    statement.executeUpdate(query)
  } finally {
    statement?.close()
    connection?.close()
  }
}
