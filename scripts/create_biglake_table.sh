# Create biglake table def
bq mkdef \
--source_format=PARQUET \
--connection_id=us.zeals_connection \
--hive_partitioning_mode=CUSTOM \
--hive_partitioning_source_uri_prefix=gs: //zeals_dataset/bikeshare/{trip_date:DATE}/{trip_hour:STRING} \
--require_hive_partition_filter=false \
--metadata_cache_mode=MANUAL \
gs: //zeals_dataset/bikeshare/* > mytable_def

# Create biglake table
bq mk --external_table_definition=mytable_def \
zeals_biglake_dataset.bikeshare_trips_biglake \
trip_id:INTEGER,start_time:TIMESTAMP,start_station_id:INTEGER,start_station_name:STRING,end_station_id:INTEGER,end_station_name:STRING,duration_minutes:INTEGER
