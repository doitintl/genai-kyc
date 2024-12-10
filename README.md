# AWS KYC Processing System with Fraud Detection

A scalable Know Your Customer (KYC) processing system built on AWS infrastructure, featuring document processing, secure storage, and AI-powered fraud detection using Amazon Bedrock.

## Features

- Secure document storage in S3 with server-side encryption
- Automated KYC document processing using AWS Lambda
- Real-time fraud detection powered by Amazon Bedrock
- RESTful API endpoint through API Gateway
- Metadata storage in DynamoDB
- Infrastructure as Code using Terraform
- Comprehensive error handling and logging

## Architecture

The system consists of several key components:
- S3 bucket for secure document storage
- DynamoDB table for KYC metadata
- Lambda function for document processing
- API Gateway for REST endpoint exposure
- Amazon Bedrock for AI-powered fraud detection
- Multiple AI models for comprehensive analysis:
  - Anomaly Detection
  - Pattern Recognition
  - NLP for Text Analysis
  - Behavior Analysis

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 0.12
- Python >= 3.9
- AWS CLI configured
- Boto3 Python SDK
- Access to Amazon Bedrock service

## Installation

1. Clone the repository
2. Install dependencies:
```bash
pip install boto3 requests
```

3. Initialize Terraform:
```bash
terraform init
```

4. Deploy the infrastructure:
```bash
terraform plan
terraform apply
```

## Configuration

1. Update the S3 bucket name in `terraform.tf`:
```hcl
resource "aws_s3_bucket" "kyc_documents" {
  bucket = "your-kyc-documents-bucket"
}
```

2. Configure environment variables:
```bash
export API_URL="your-api-gateway-url"
```

## Usage

1. Upload KYC documents:
```python
import boto3
s3_client = boto3.client('s3')
s3_client.upload_file('document.pdf', 'your-kyc-documents-bucket', 'user_id/document.pdf')
```

2. Process KYC verification:
```python
response = call_kyc_api(user_id="user123", document_id="doc123")
```
