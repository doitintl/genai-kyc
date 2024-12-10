import boto3
import os
import json
import base64

# Initialize AWS clients
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
bedrock = boto3.client('bedrock-runtime')

def lambda_handler(event, context):
    # Get environment variables
    bucket_name = os.environ['S3_BUCKET']
    table_name = os.environ['DYNAMODB_TABLE']
    
    # Get the DynamoDB table
    table = dynamodb.Table(table_name)
    
    # Extract information from the event
    body = json.loads(event['body'])
    user_id = body['user_id']
    document_id = body['document_id']
    
    try:
        # Retrieve the image from S3
        s3_response = s3.get_object(Bucket=bucket_name, Key=f"{user_id}/{document_id}")
        image_content = s3_response['Body'].read()
        
        # Encode the image as base64
        image_base64 = base64.b64encode(image_content).decode('utf-8')
        
        # Prepare the request for Bedrock
        bedrock_request = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1000,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "Please analyze this image for KYC purposes. Extract any relevant information such as name, date of birth, address, and document type. Also, check for any signs of tampering or fraudulent alterations. Provide a risk score between 1 and 10 with 10 being high risk. The output is to be provided in json format."
                        },
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": image_base64
                            }
                        }
                    ]
                }
            ]
        }
        
        # Make the call to Bedrock
        bedrock_response = bedrock.invoke_model(
            body=json.dumps(bedrock_request),
            modelId="anthropic.claude-3-sonnet-20240229-v1:0",
            accept='application/json',
            contentType='application/json'
        )
        
        # Parse the Bedrock response
        bedrock_result = json.loads(bedrock_response['body'].read())
        analysis = bedrock_result['content'][0]['text']
        
        # Store the analysis result in DynamoDB
        table.put_item(
            Item={
                'user_id': user_id,
                'document_id': document_id,
                'analysis': analysis
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'KYC analysis completed successfully',
                'analysis': analysis
            })
        }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error processing KYC document',
                'error': str(e)
            })
        }