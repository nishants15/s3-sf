pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        // Clone the GitHub repository
        git branch: 'integration', credentialsId: 'GH-credentials', url: 'https://github.com/nishants15/s3-sf.git'
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
          def s3_bucket_name = 'snowflake-input11'
          def file_format_name = 'my_file_format'
          def warehouse = 'comput_wh'
          def stage_name = 's3_stage'
          def table_name = 'stg_campaign1'

          // Add the Snowflake JDBC driver to the classpath
          def jdbcDriverPath = '/opt/snowflake-jdbc-3.13.7.jar' // Path to Snowflake JDBC driver JAR file
          def loader = new URLClassLoader([new URL("file:${jdbcDriverPath}")], this.getClass().getClassLoader())
          def driverClass = loader.loadClass('net.snowflake.client.jdbc.SnowflakeDriver')
          DriverManager.registerDriver(driverClass.newInstance())

          def jdbcUrl = "jdbc:snowflake://${snowflake_account}/?user=${snowflake_user}&password=${snowflake_password}"

          // Create or replace the stage
          def createStageQuery = """
            CREATE OR REPLACE STAGE ${stage_name}
            URL='s3://${s3_bucket_name}/'
            FILE_FORMAT=${file_format_name};
          """

          // Execute the CREATE STAGE query
          sqlExecute(jdbcUrl, createStageQuery)

          // Snowflake COPY command
          def copyCommand = """
            COPY INTO ${snowflake_schema}.${table_name}
            FROM (SELECT \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12,\$13,\$14,\$15,\$16,\$17,\$18,\$19,\$20,
              METADATA\$FILENAME, CURRENT_TIMESTAMP(), 'Not Processed', NULL
              FROM @${stage_name})
            PATTERN='.*Campaign1.*[.]csv';
          """

          // Execute the COPY command
          sqlExecute(jdbcUrl, copyCommand)
        }
      }
    }
  }
}

import java.sql.DriverManager

def sqlExecute(jdbcUrl, query) {
  def connection = DriverManager.getConnection(jdbcUrl)
  def statement = connection.createStatement()

  try {
    statement.executeUpdate(query)
  } finally {
    statement?.close()
    connection?.close()
  }
}
