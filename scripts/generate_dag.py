"""
Script to dynamically generate DAGs.
"""
import json
import os
import shutil
import fileinput


TEMPLATE_FILE = 'templates/process_file.py'

for filename in os.listdir('config/'):
    print(filename)
    if filename.endswith('.json'):
        with open(f"config/{filename}") as f:
            config = json.load(f)
            new_dag_file = f"dags/process_{config['dag_id']}.py"
            shutil.copyfile(TEMPLATE_FILE, new_dag_file)
            for line in fileinput.input(new_dag_file, inplace=True):
                line = line.replace('DAG_ID_PLACEHOLDER', config['dag_id'])
                line = line.replace('SCHEDULE_INTERVAL_PLACEHOLDER', config['schedule_interval'])
                line = line.replace('INPUT_PLACEHOLDER', config['input'])
                print(line, end='')