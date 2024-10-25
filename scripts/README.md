# scripts

Helper scripts for the training session.

## `input-data.sh`
Used by the sensor example DAG. Copies or removes an object from S3.

## `copy-dags-to-s3.sh`
Copies the dags directory to the expected S3 path according to the MWAA configuration.

## `generate_dag.py`
Used to create multiple DAGs that are similar, using config files.