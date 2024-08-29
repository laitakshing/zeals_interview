FROM apache/airflow:2.6.3-python3.11

USER root 

# Downloading gcloud package
RUN curl https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz

# Installing the package
RUN mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
  && /usr/local/gcloud/google-cloud-sdk/install.sh



USER airflow

# Adding the package path to local
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin
ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python

# gcloud auth login
COPY ./scripts/service_account.json /opt/airflow/service_account.json
ENV GOOGLE_APPLICATION_CREDENTIALS="/opt/airflow/service_account.json"
RUN /usr/local/gcloud/google-cloud-sdk/bin/gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt


# Setup Airflow
RUN airflow db init
