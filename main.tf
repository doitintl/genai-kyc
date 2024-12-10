# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# S3 bucket for storing KYC documents
resource "aws_s3_bucket" "kyc_documents" {
  bucket = "kyc-documents-bucket-asdfg"

}


# S3 bucket versioning
resource "aws_s3_bucket_versioning" "kyc_documents_versioning" {
  bucket = aws_s3_bucket.kyc_documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "kyc_documents_encryption" {
  bucket = aws_s3_bucket.kyc_documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table for storing KYC metadata
resource "aws_dynamodb_table" "kyc_metadata" {
  name           = "kyc-metadata"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "document_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "document_id"
    type = "S"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "kycFunction.py"
  output_path = "kycFunction.zip"
}

# Lambda function for processing KYC documents (Python)
resource "aws_lambda_function" "kyc_processor" {
  filename      = "kycFunction.zip"
  function_name = "kycFunction"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "kycFunction.lambda_handler"
  runtime       = "python3.9"
  timeout = 120

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.kyc_documents.id
      DYNAMODB_TABLE = aws_dynamodb_table.kyc_metadata.name
    }
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_exec" {
  name = "kyc-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda function
resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

# Additional policies for S3 and DynamoDB access
resource "aws_iam_role_policy" "lambda_s3_dynamodb_access" {
  name = "lambda-s3-dynamodb-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_s3_bucket.kyc_documents.arn,
          "${aws_s3_bucket.kyc_documents.arn}/*",
          aws_dynamodb_table.kyc_metadata.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
  role       = aws_iam_role.lambda_exec.name
}

# API Gateway
resource "aws_api_gateway_rest_api" "kyc_api" {
  name        = "kyc-api"
  description = "KYC API Gateway"
}

resource "aws_api_gateway_resource" "kyc_resource" {
  rest_api_id = aws_api_gateway_rest_api.kyc_api.id
  parent_id   = aws_api_gateway_rest_api.kyc_api.root_resource_id
  path_part   = "kyc"
}

resource "aws_api_gateway_method" "kyc_post" {
  rest_api_id   = aws_api_gateway_rest_api.kyc_api.id
  resource_id   = aws_api_gateway_resource.kyc_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.kyc_api.id
  resource_id = aws_api_gateway_resource.kyc_resource.id
  http_method = aws_api_gateway_method.kyc_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.kyc_processor.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kyc_processor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.kyc_api.execution_arn}/*/*"
}