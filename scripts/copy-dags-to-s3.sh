#!/usr/bin/env bash
# This script copies the dags directory to S3
# Check if the script is run from the base of the repo
if [ ! -f "./scripts/copy-dags-to-s3.sh" ]; then
    echo "Please run this script from the base of the repository."
    exit 1
fi

# Check if aws-credentials.json exists
if [ ! -f "aws-credentials.json" ]; then
    echo "aws-credentials.json file not found!"
    exit 1
fi

# Set your AWS credentials
export AWS_ACCESS_KEY_ID=$(cat aws-credentials.json | jq -r '.access_key_id')
export AWS_SECRET_ACCESS_KEY=$(cat aws-credentials.json | jq -r '.secret')
export AWS_DEFAULT_REGION=$(cat aws-credentials.json | jq -r '.default_region')

aws sts get-caller-identity

LOCAL_DAGS_DIR="dags"
S3_DAGS_DIR="s3://airflow-bucket-cobank/dags/"

aws s3 cp --recursive $LOCAL_DAGS_DIR $S3_DAGS_DIR
