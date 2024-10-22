from datetime import datetime, timedelta
from airflow.decorators import dag, task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
from src.utils import S3_BUCKET
from io import StringIO


@dag(
    description="A DAG demonstrating the use of an S3 sensor and CSV processing",
    schedule_interval=timedelta(days=1),
    start_date=datetime(2024, 10, 18),
    catchup=False,
    tags=["sensor", "s3"],
)
def sensor_example():

    bucket_name = S3_BUCKET
    input_file_name = "data/input/people.csv"
    output_file_name = "data/processed/sorted_people.csv"

    wait_for_file = S3KeySensor(
        task_id="wait_for_file",
        bucket_name=bucket_name,
        bucket_key=input_file_name,
        poke_interval=60,
        timeout=3600,
        mode="poke",
    )

    @task
    def process_file(bucket: str, input_key: str, output_key: str):
        import pandas as pd

        # Initialize S3 hook
        s3_hook = S3Hook()

        # Read CSV file from S3
        input_file_content = s3_hook.read_key(key=input_key, bucket_name=bucket)
        df = pd.read_csv(StringIO(input_file_content))

        # Sort the dataframe by age, from youngest to oldest
        df_sorted = df.sort_values("age")

        # Convert the sorted dataframe back to CSV
        output_buffer = StringIO()
        df_sorted.to_csv(output_buffer, index=False)

        # Upload the sorted CSV back to S3
        s3_hook.load_string(
            string_data=output_buffer.getvalue(),
            key=output_key,
            bucket_name=bucket,
            replace=True,
        )

        print(f"Processed and sorted CSV saved to s3://{bucket}/{output_key}")

    # Define the task dependencies
    wait_for_file >> process_file(bucket_name, input_file_name, output_file_name)


# Instantiate the DAG
sensor_example()
