
use database dev_convertr;
create or replace stage dev_convertr.stage.s3_stage url='s3://snowflake-input11'
    STORAGE_INTEGRATION = s3_int
    FILE_FORMAT = dev_convertr.stage.my_file_format;