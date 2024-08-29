from airflow import DAG
from airflow.operators.python import PythonOperator
from google.cloud import bigquery
import pandas as pd
from datetime import datetime, timedelta
import gcsfs
from concurrent.futures import ThreadPoolExecutor
from airflow.utils.dates import days_ago

# Default arguments for the DAG
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

# Define the DAG
with DAG(
    "bikeshare_etl",
    default_args=default_args,
    description="Extract data from BigQuery, save as Parquet, and upload to GCS",
    schedule_interval=None,  # Manual trigger
    start_date=days_ago(1),  # Default start date
    catchup=False,
) as dag:

    def extract_data_from_bigquery(**kwargs):
        # Retrieve parameters passed during DAG trigger
        start_date = kwargs["dag_run"].conf.get("start_date")
        end_date = kwargs["dag_run"].conf.get("end_date")

        # Fallback to yesterday's date if parameters are not provided
        if not start_date:
            start_date = (datetime.today() - timedelta(days=1)).strftime("%Y-%m-%d")
        if not end_date:
            end_date = start_date

        # Log the dates being used
        print(f"Running DAG with start_date={start_date} and end_date={end_date}")

        # Initialize BigQuery client
        client = bigquery.Client(project="zeals-interview")

        # SQL query to extract data for the specified date range
        query = f"""
        SELECT 
            trip_id,
            start_time,
            start_station_id,
            start_station_name,
            end_station_id,
            end_station_name,
            duration_minutes,
            FORMAT_TIMESTAMP('%Y-%m-%d', start_time) as trip_date,
            FORMAT_TIMESTAMP('%H', start_time) as trip_hour
        FROM 
            `bigquery-public-data.austin_bikeshare.bikeshare_trips`
        WHERE 
            FORMAT_TIMESTAMP('%Y-%m-%d', start_time) BETWEEN '{start_date}' AND '{end_date}'
        """

        # Run the query and load the data into a DataFrame
        df = client.query(query).to_dataframe()

        # Cast integer columns
        int_cols = ["trip_id", "start_station_id", "end_station_id", "duration_minutes"]
        df[int_cols] = df[int_cols].astype("int64")

        # Push the DataFrame to XCom
        kwargs["ti"].xcom_push(key="dataframe", value=df)

    def upload_data_to_gcs(**kwargs):
        # Pull the DataFrame from XCom
        df = kwargs["ti"].xcom_pull(key="dataframe", task_ids="extract_data")

        # Initialize the GCS filesystem
        fs = gcsfs.GCSFileSystem()

        included_columns = [
            "trip_id",
            "start_time",
            "start_station_id",
            "start_station_name",
            "end_station_id",
            "end_station_name",
            "duration_minutes",
        ]

        def upload_file(day_df, date_str, hour):
            bucket_name = "zeals_dataset"
            base_path = f"gs://{bucket_name}/bikeshare/trip_date={date_str}/"
            file_path = f"{base_path}trip_hour={hour}/data.parquet"
            with fs.open(file_path, "wb") as f:
                day_df.to_parquet(f, index=False)
            print(f"Uploaded {file_path}")

        # Use ThreadPoolExecutor to parallelize uploads
        with ThreadPoolExecutor(max_workers=24) as executor:
            for (trip_date, trip_hour), group in df.groupby(["trip_date", "trip_hour"]):
                hour_df = group[included_columns]
                executor.submit(upload_file, hour_df, trip_date, trip_hour)

        print("Data uploaded to GCS successfully.")

    # Define the PythonOperators
    extract_task = PythonOperator(
        task_id="extract_data",
        python_callable=extract_data_from_bigquery,
        provide_context=True,
    )

    upload_task = PythonOperator(
        task_id="upload_data",
        python_callable=upload_data_to_gcs,
        provide_context=True,
    )

    # Set task dependencies
    extract_task >> upload_task
