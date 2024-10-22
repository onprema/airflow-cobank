"""
A template for dynamically generated DAGs that do file processing.
"""
from airflow import DAG
from airflow.decorators import task
from datetime import datetime

with DAG(
    "process_DAG_ID_PLACEHOLDER",
    start_date=datetime(2024, 1, 1),
    schedule_interval="SCHEDULE_INTERVAL_PLACEHOLDER",
    catchup=False,
) as dag:

    @task()
    def extract_file(file_path):
        print(f"Extracting file from {file_path}")
        return file_path

    @task()
    def process_file(file_path):
        print(f"Processing file from {file_path}")
        return file_path

    @task()
    def send_email(file_path):
        print(f"Sending email with file {file_path}")
        return file_path

    send_email(process_file(extract_file("INPUT_PLACEHOLDER")))
