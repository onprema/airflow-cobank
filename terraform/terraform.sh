#!/usr/bin/env bash
# Usage: ./terraform/terraform.sh <command>

# Check if aws-credentials.json exists
if [[ ! -f "aws-credentials.json" ]]; then
    echo "Error: aws-credentials.json file not found!"
    exit 1
fi

# Set your AWS credentials
export AWS_ACCESS_KEY_ID=$(cat aws-credentials.json | jq -r '.access_key_id')
export AWS_SECRET_ACCESS_KEY=$(cat aws-credentials.json | jq -r '.secret')
export AWS_DEFAULT_REGION=$(cat aws-credentials.json | jq -r '.default_region')

aws sts get-caller-identity

# Run terraform commands
cd terraform
terraform "$@"