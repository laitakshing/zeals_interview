
# (Zeals Task) BigLake Table with Airflow on GCP

## Overview

This project demonstrates how to build a BigLake table in Google Cloud Platform (GCP) and use Apache Airflow to manage ETL processes. The project includes a Docker Compose setup to host an Airflow environment and automate the workflow.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Environment Setup](#environment-setup)
- [Running the Project](#running-the-project)
- [Triggering the Airflow DAG](#triggering-the-airflow-dag)
- [Troubleshooting](#troubleshooting)
- [Reference](#reference)

## Prerequisites

Before you begin, ensure you have the following installed on your local machine:

- **Docker**: [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose**: [Install Docker Compose](https://docs.docker.com/compose/install/)
- **Google Cloud SDK**: [Install Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

Additionally, you need a Google Cloud project with the following services enabled:

- **BigQuery**
- **Google Cloud Storage**
- **BigLake**

You should also have a service account with the necessary permissions and a corresponding `service_account.json` key file.

## Project Structure

Here's an overview of the project structure:

```
your_project/
├── dags/
│   └── bikeshare_etl.py            # The Airflow DAG for the ETL process
├── scripts/
│   └── service_account.json        # Google Cloud service account credentials
│   └── analysis.sql                # The SQL Query for Task 5 Data Analysis
│   └── create_biglake_table.sh     # GCloud command to Create Biglake table
├── logs/                           # Logs folder 
├── Dockerfile                      # Dockerfile for building the Airflow environment
├── docker-compose.yml              # Docker Compose configuration for Airflow services
├── requirements.txt                # Python dependencies for Airflow
└── README.md                       # This README file
```

### Project Files

- **dags/bikeshare_etl.py**: The DAG script defining the ETL process, including tasks for extracting data from BigQuery public dataset bikeshare and uploading it to Google Cloud Storage as Hive partitioned data format
- **scripts/service_account.json**: The Google Cloud service account JSON key used for authentication.
- **scripts/analysis.sql**: Include 9 Bigquery queries for Task 5 Data Analysis
- **scripts/create_biglake_table.sh**: The GCloud command to create bigLake Table on Hive partitioned data
- **logs**: Logs folder to be mounted by airflow  
- **Dockerfile**: The Dockerfile for creating the Airflow environment with the required dependencies.
- **docker-compose.yml**: The Docker Compose file to set up Airflow services like the webserver and scheduler and PostgreSQL.
- **requirements.txt**: Lists the Python dependencies needed for Airflow.

## Environment Setup

### 0. Rename the variable

In this project, I will use the following naming, please change it or just name it same as it:

```
project_name = zeals-interview
dataset_name = zeals_biglake_dataset
table_name = bikeshare_trips_biglake
bucket_path = zeals_dataset/bikeshare
```

### 1. Create Cloud Storage bucket with the following structure

```
zeals_dataset/
├── bikeshare/
```
![image](https://github.com/user-attachments/assets/6c59589f-9444-4339-9b1c-9d8065ce6748)

### 2. Create Biglake table using the command in scripts/create_biglake_table.sh

Run the gcloud bq command in Google console
```
# Create biglake table def
bq mkdef \
--source_format=PARQUET \
--connection_id=us.zeals_connection \
--hive_partitioning_mode=CUSTOM \
--hive_partitioning_source_uri_prefix=gs://zeals_dataset/bikeshare/{trip_date:DATE}/{trip_hour:STRING} \
--require_hive_partition_filter=false \
--metadata_cache_mode=MANUAL \
gs://zeals_dataset/bikeshare/* > mytable_def

# Create biglake table
bq mk --external_table_definition=mytable_def \
zeals_biglake_dataset.bikeshare_trips_biglake \
trip_id:INTEGER,start_time:TIMESTAMP,start_station_id:INTEGER,start_station_name:STRING,end_station_id:INTEGER,end_station_name:STRING,duration_minutes:INTEGER
```
You will see `Table 'zeals-interview:zeals_biglake_dataset.bikeshare_trips_biglake' successfully created.` 


### 3. Google Cloud Authentication

Place the `service_account.json` file in the `scripts/` directory. This file will be used by the Airflow DAG to authenticate with Google Cloud services.

### 4. Docker Setup

Ensure Docker and Docker Compose are installed and running on your local machine.

### 5. Build the Docker Image

Follow and construct the project folder structure(please add logs folder) and build the Docker image for the Airflow environment:

```bash
docker compose -p zeal-airflow build 
```

### 6. Start Airflow Services

Start the Airflow services using Docker Compose:

```bash
docker-compose up -d
```

This command will start the Airflow webserver, scheduler, and PostgreSQL database in the background.

## Running the Project

### 1. Access the Airflow UI

Once the services are running, you can access the Airflow UI by navigating to:

```
http://localhost:8080
```

Login using the default credentials (if configured in the `docker-compose.yml`):

- Username: `airflow`
- Password: `airflow`

### 2. Check if the Dag exist

If you setup correctly, you can see the dag:

![image](https://github.com/user-attachments/assets/86b935c3-fa14-45b9-a4ca-52b8e0788832)


## Triggering the Airflow DAG

### 1. Manual Trigger

To manually trigger the DAG:

#### Trigger DAG (It will get the yesterday data and store it in GCS)
- Go to the **DAGs** page in the Airflow UI.
- Click on the toggle switch to enable the DAG.
- Click on the **Trigger DAG** button to start the ETL process.

#### Trigger DAG w/config (We can manually add a JSON to backfill data)
- Go to the **DAGs** page in the Airflow UI.
- Click on the toggle switch to enable the DAG.
- Click on the **Trigger DAG w/config** button to start the ETL process.
- Fill in the Configuration JSON like this
![image](https://github.com/user-attachments/assets/9456dd30-1b39-4ec2-85a1-5563359d1447)
- Click on the **Trigger**


### 2. Automatic Scheduling

You can also set up the DAG to run on a schedule by modifying the `schedule_interval` in the DAG file (`bikeshare_etl.py`).

### 3. Check the data in GCS

When the DAG run is completed, you can check the GCS folder to see if the data is uploaded
![image](https://github.com/user-attachments/assets/b66f059e-b22b-4b57-83b7-753c7364cdcd)

### 4. Run the Query in scripts/analysis.sql in Bigquery Console
![image](https://github.com/user-attachments/assets/4df21d50-867a-4d5e-9a41-86dd1cbd8294)



## Troubleshooting

### 1. Logs

If you encounter issues, check the logs for each service:

```bash
docker-compose logs airflow-webserver
docker-compose logs airflow-scheduler
```

### 2. Common Issues

- **Service Account Key Not Found**: Ensure the `service_account.json` file is correctly placed in the `scripts/` directory.
- **Airflow UI Not Accessible**: Check if the Docker services are running with `docker ps`. Restart the services if needed.

### 3. Remarks

1. We are using ‘wb’ mode so it will truncates and recreate file if it already exists and creates a new file if it does not exist. Thus, It is safe to re-run the dag
2. For creating a biglake table programmatically, it only work when using gcloud bq command, escpecially on Hive partition data. I need more time for other method like SQL
3. For Airflow Docker compose, I just adopt the basic setup(i.e. no additional workers) since no special requirement.
4. I did not upload my service-account key for security issue

## Reference

1. **BiglakeTable**: [Create Biglake Table](https://docs.docker.com/get-docker/](https://cloud.google.com/bigquery/docs/create-cloud-storage-table-biglake#create-biglake-partitioned-data))
2. **Airflow in Docker compose**:[Airflow](https://airflow.apache.org/docs/apache-airflow/2.0.2/start/docker.html)
3. **ChatGPT**
