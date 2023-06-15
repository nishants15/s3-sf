pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        // Clone the GitHub repository
        git branch: 'integration', credentialsId: 'GH-credentials', url: 'https://github.com/nishants15/S3-INT-SF.git'
      }
    }

    stage('Transfer CSV to Snowflake') {
      steps {
        script {
          snowflake_user = 'mark'
          snowflake_password = 'Mark6789*'
          snowflake_account = 'kx23846.ap-southeast-1'
          snowflake_database = 'dev_convertr'
          snowflake_schema = 'stage'
          s3_bucket_name = 'snowflake-input11'
          file_format_name = 'my_file_format'
          warehouse = 'comput_wh'
          stage_name = 's3_stage'
          table_name = 'stg_campaign1'

          def jdbcDriverPath = def jdbcDriverPath = '/opt/snowflake-jdbc-3.13.7.jar' Path to Snowflake JDBC driver JAR file
          def jdbcUrl = "jdbc:snowflake://${snowflake_account}/?user=${snowflake_user}&password=${snowflake_password}"

          // Create or replace the stage
          def createStageQuery = """
            CREATE OR REPLACE STAGE ${stage_name}
            URL='s3://${s3_bucket_name}/'
            FILE_FORMAT=${file_format_name};
          """

          // Execute the CREATE STAGE query
          sqlExecute(jdbcDriverPath, jdbcUrl, createStageQuery)

          // Snowflake COPY command
          def copyCommand = """
            COPY INTO ${snowflake_schema}.${table_name}
            FROM (SELECT \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12,\$13,\$14,\$15,\$16,\$17,\$18,\$19,\$20,
              METADATA\$FILENAME, CURRENT_TIMESTAMP(), 'Not Processed', NULL
              FROM @${stage_name})
            PATTERN='.*Campaign1.*[.]csv';
          """

          // Execute the COPY command
          sqlExecute(jdbcDriverPath, jdbcUrl, copyCommand)
        }
      }
    }
  }
}

def sqlExecute(jdbcDriverPath, jdbcUrl, query) {
  def driverLoader = new URLClassLoader([new File(jdbcDriverPath).toURI().toURL()])
  def driverClass = Class.forName('net.snowflake.client.jdbc.SnowflakeDriver', true, driverLoader)
  DriverManager.registerDriver(new DriverWrapper(driverClass.newInstance()))

  def connection = DriverManager.getConnection(jdbcUrl)
  def statement = connection.createStatement()

  try {
    statement.executeUpdate(query)
  } finally {
    statement?.close()
    connection?.close()
  }
}
