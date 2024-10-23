from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

from src.basic_example import print_hello
from src.utils import AIRFLOW_HOME

# Define default_args dictionary to specify the default parameters of the DAG
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": datetime(2024, 1, 1),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

# Define the DAG
with DAG(
    "basic_example",
    default_args=default_args,
    description="A simple DAG",
    schedule_interval=timedelta(days=1),
    catchup=False,
) as dag:

    # Task 1: BashOperator
    t1 = BashOperator(task_id="bash_task_1", bash_command="date +%s")

    # Task 2: PythonOperator
    t2 = PythonOperator(task_id="python_task", python_callable=print_hello)

    # Task 3: BashOperator
    t3 = BashOperator(
        task_id="bash_task_2",
        bash_command="bash " + AIRFLOW_HOME + "/dags/src/example_script.sh {{ds}}",
    )

    # Set task dependencies
    t1 >> [t2, t3]

if __name__ == "__main__":
    dag.test()
