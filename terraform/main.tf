# Provider configuration
provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "airflow_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "airflow-vpc"
  }
}

# Subnets
resource "aws_subnet" "airflow_private_subnet_1" {
  vpc_id            = aws_vpc.airflow_vpc.id
  cidr_block        = "10.0.0.0/18"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "airflow-private-1"
  }
}

resource "aws_subnet" "airflow_private_subnet_2" {
  vpc_id            = aws_vpc.airflow_vpc.id
  cidr_block        = "10.0.64.0/18"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "airflow-private-2"
  }
}

resource "aws_subnet" "airflow_public_subnet_1" {
  vpc_id                  = aws_vpc.airflow_vpc.id
  cidr_block              = "10.0.128.0/18"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "airflow-public-1"
  }
}

resource "aws_subnet" "airflow_public_subnet_2" {
  vpc_id                  = aws_vpc.airflow_vpc.id
  cidr_block              = "10.0.192.0/18"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "airflow-public-2"
  }
}

# NAT Gateways
resource "aws_eip" "nat_gateway_1_eip" {
  domain = "vpc"
}

resource "aws_eip" "nat_gateway_2_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1_eip.id
  subnet_id     = aws_subnet.airflow_public_subnet_1.id
}

resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_gateway_2_eip.id
  subnet_id     = aws_subnet.airflow_public_subnet_2.id
}

# Internet Gateway
resource "aws_internet_gateway" "airflow_igw" {
  vpc_id = aws_vpc.airflow_vpc.id

  tags = {
    Name = "airflow-igw"
  }
}

# Route Tables
resource "aws_route_table" "airflow_public_rt" {
  vpc_id = aws_vpc.airflow_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.airflow_igw.id
  }

  tags = {
    Name = "airflow-public-rt"
  }
}

resource "aws_route_table" "airflow_private_rt_1" {
  vpc_id = aws_vpc.airflow_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  }

  tags = {
    Name = "airflow-private-rt-1"
  }
}

resource "aws_route_table" "airflow_private_rt_2" {
  vpc_id = aws_vpc.airflow_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_2.id
  }

  tags = {
    Name = "airflow-private-rt-2"
  }
}

# Route Table Association
resource "aws_route_table_association" "airflow_public_rta_1" {
  subnet_id      = aws_subnet.airflow_public_subnet_1.id
  route_table_id = aws_route_table.airflow_public_rt.id
}

resource "aws_route_table_association" "airflow_public_rta_2" {
  subnet_id      = aws_subnet.airflow_public_subnet_2.id
  route_table_id = aws_route_table.airflow_public_rt.id
}

resource "aws_route_table_association" "airflow_private_rta_1" {
  subnet_id      = aws_subnet.airflow_private_subnet_1.id
  route_table_id = aws_route_table.airflow_private_rt_1.id
}

resource "aws_route_table_association" "airflow_private_rta_2" {
  subnet_id      = aws_subnet.airflow_private_subnet_2.id
  route_table_id = aws_route_table.airflow_private_rt_2.id
}

# Security Group
resource "aws_security_group" "airflow_sg" {
  name        = "airflow-sg"
  description = "Security group for Airflow MWAA"
  vpc_id      = aws_vpc.airflow_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "airflow-sg"
  }
}

# S3 Bucket for Airflow DAGs and plugins
resource "aws_s3_bucket" "airflow_bucket" {
  bucket = "airflow-bucket-cobank"
  tags = {
    Name = "airflow-bucket"
  }
}

# Enable versioning on the bucket
resource "aws_s3_bucket_versioning" "airflow_bucket" {
  bucket = aws_s3_bucket.airflow_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "airflow_bucket" {
  bucket = aws_s3_bucket.airflow_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "airflow_bucket" {
  bucket                  = aws_s3_bucket.airflow_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload DAGs
resource "aws_s3_object" "airflow_dags" {
  for_each = fileset("../dags/", "*")
  bucket   = aws_s3_bucket.airflow_bucket.id
  key      = "dags/${each.value}"
  source   = "../dags/${each.value}"
  etag     = filemd5("../dags/${each.value}")
}

# S3 Object for requirements.txt
resource "aws_s3_object" "requirements" {
  bucket = aws_s3_bucket.airflow_bucket.bucket
  key    = "requirements.txt"
  source = "../requirements.txt"
  etag   = filemd5("../requirements.txt")

  depends_on = [aws_s3_bucket.airflow_bucket]
}

# IAM Role for MWAA
resource "aws_iam_role" "airflow_role" {
  name = "airflow-mwaa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "airflow-env.amazonaws.com"
        }
      }
    ]
  })
}

# Custom IAM policy for MWAA
resource "aws_iam_policy" "mwaa_execution_policy" {
  name        = "mwaa-execution-policy"
  description = "IAM policy for MWAA execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "airflow:*",
          "cloudwatch:*",
          "logs:*",
          "s3:*",
          "sqs:*",
          "kms:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the custom policy to the IAM role
resource "aws_iam_role_policy_attachment" "mwaa_policy_attachment" {
  policy_arn = aws_iam_policy.mwaa_execution_policy.arn
  role       = aws_iam_role.airflow_role.name
}

# MWAA Environment
resource "aws_mwaa_environment" "airflow_env" {
  name               = "cobank-airflow-environment"
  airflow_version    = "2.10.1"
  environment_class  = "mw1.small"
  max_workers        = 2
  min_workers        = 1
  dag_s3_path        = "dags/"
  execution_role_arn = aws_iam_role.airflow_role.arn

  # Airflow configurations
  airflow_configuration_options = {
    "webserver.expose_config"         = "True"
    "core.load_examples"              = "False"
    "scheduler.dag_dir_list_interval" = "30"
  }

  # Make the webserver endpoint public
  webserver_access_mode = "PUBLIC_ONLY"

  source_bucket_arn = aws_s3_bucket.airflow_bucket.arn

  # Add configuration for requirements.txt location
  requirements_s3_path = "requirements.txt"

  network_configuration {
    security_group_ids = [aws_security_group.airflow_sg.id]
    subnet_ids         = [aws_subnet.airflow_private_subnet_1.id, aws_subnet.airflow_private_subnet_2.id]
  }


  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }

    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }

    task_logs {
      enabled   = true
      log_level = "INFO"
    }

    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }

    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }
}
# Output the Airflow Web UI URL
output "airflow_webserver_url" {
  value = aws_mwaa_environment.airflow_env.webserver_url
}

# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
}
