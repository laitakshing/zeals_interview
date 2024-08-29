
# BigLake Table with Airflow on GCP

## Overview

This project demonstrates how to build a BigLake table in Google Cloud Platform (GCP) and use Apache Airflow to manage ETL processes. The project includes a Docker Compose setup to host an Airflow environment and automate the workflow.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Environment Setup](#environment-setup)
- [Running the Project](#running-the-project)
- [Triggering the Airflow DAG](#triggering-the-airflow-dag)
- [Troubleshooting](#troubleshooting)
- [License](#license)

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
├── Dockerfile                      # Dockerfile for building the Airflow environment
├── docker-compose.yml              # Docker Compose configuration for Airflow services
├── requirements.txt                # Python dependencies for Airflow
└── README.md                       # This README file
```

### Project Files

- **dags/bikeshare_etl.py**: The DAG script defining the ETL process, including tasks for extracting data from BigQuery and uploading it to Google Cloud Storage.
- **scripts/service_account.json**: The Google Cloud service account JSON key used for authentication.
- **Dockerfile**: The Dockerfile for creating the Airflow environment with the required dependencies.
- **docker-compose.yml**: The Docker Compose file to set up Airflow services like the webserver and scheduler.
- **requirements.txt**: Lists the Python dependencies needed for Airflow.

## Environment Setup

### 1. Google Cloud Authentication

Place the `service_account.json` file in the `scripts/` directory. This file will be used by the Airflow DAG to authenticate with Google Cloud services.

### 2. Docker Setup

Ensure Docker and Docker Compose are installed and running on your local machine.

### 3. Build the Docker Image

Build the Docker image for the Airflow environment:

```bash
docker-compose build
```

### 4. Start Airflow Services

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

- Username: `admin`
- Password: `admin_password`

### 2. Set Up Airflow Connections

Make sure to set up the necessary Airflow connections for Google Cloud. In the Airflow UI:

- Navigate to **Admin > Connections**.
- Add a new connection with the following details:
  - **Conn Id**: `google_cloud_default`
  - **Conn Type**: `Google Cloud`
  - **Keyfile Path**: `/opt/airflow/scripts/service_account.json`
  - **Project Id**: Your Google Cloud Project ID

## Triggering the Airflow DAG

### 1. Manual Trigger

To manually trigger the DAG:

- Go to the **DAGs** page in the Airflow UI.
- Click on the toggle switch to enable the DAG.
- Click on the **Trigger DAG** button to start the ETL process.

### 2. Automatic Scheduling

You can also set up the DAG to run on a schedule by modifying the `schedule_interval` in the DAG file (`bikeshare_etl.py`).

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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
