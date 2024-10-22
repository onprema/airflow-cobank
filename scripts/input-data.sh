#!/usr/bin/env bash
# This script copies or removes data from an S3 bucket based on the provided argument.
# Usage: ./input-data.sh [cp|rm]

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

if [ "$1" == "cp" ]; then
    aws s3 cp data/people.csv s3://airflow-bucket-cobank/data/input/people.csv
elif [ "$1" == "rm" ]; then
    aws s3 rm s3://airflow-bucket-cobank/data/input/people.csv
    aws s3 rm s3://airflow-bucket-cobank/data/processed/sorted_people.csv
else
    echo "Invalid argument. Use 'cp' to copy or 'rm' to remove."
    exit 1
fi