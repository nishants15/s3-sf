  copy into stage.stg_campaign1
  from (select $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,METADATA$FILENAME,current_timestamp(),'Not Processed', null from @S3_Stage)
  pattern='.*Campaign1.*[.]csv';


  