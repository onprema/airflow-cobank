"""
A basic DAG that uses the TaskFlow API:
https://airflow.apache.org/docs/apache-airflow/stable/tutorial/taskflow.html
"""
from datetime import datetime, timedelta
from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

@dag(
    default_args=default_args,
    description='A basic DAG using the TaskFlow API',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['examples'],
)
def basic_taskflow_example():

    @task()
    def get_message():
        return 'Hello there!'

    @task()
    def process_message(message):
        print(f"Received: {message}")
        return "Processed " + message

    # TaskFlow API tasks
    message = get_message()
    process_message(message)

# Invoke the DAG
basic_taskflow_example()
