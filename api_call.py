import boto3
import requests
import json
import os
from botocore.exceptions import ClientError

# AWS Configuration
AWS_REGION = "us-west-2"
S3_BUCKET = "kyc-documents-bucket-asdfg"

# API Configuration
API_URL = "API URL"

# User and Document Information
USER_ID = "user1235"
DOCUMENT_ID = "id1235"
FILE_PATH = "ids/id1235.jpg"

def upload_file_to_s3(file_path, bucket, object_name=None):
    """Upload a file to an S3 bucket

    :param file_path: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """
    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = os.path.basename(file_path)

    # Upload the file
    s3_client = boto3.client('s3', region_name=AWS_REGION)
    try:
        s3_client.upload_file(file_path, bucket, f"{USER_ID}/{object_name}")
    except ClientError as e:
        print(f"Error uploading file to S3: {e}")
        return False
    return True

def call_kyc_api(user_id, document_id):
    """Make a POST request to the KYC API

    :param user_id: User ID for KYC process
    :param document_id: Document ID for KYC process
    :return: API response
    """
    payload = {
        "user_id": user_id,
        "document_id": document_id
    }
    headers = {
        "Content-Type": "application/json"
    }
    try:
        response = requests.post(API_URL, json=payload, headers=headers)
        response.raise_for_status()  # Raises a HTTPError if the status is 4xx, 5xx
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error calling KYC API: {e}")
        return None

def main():
    # Upload file to S3
    if upload_file_to_s3(FILE_PATH, S3_BUCKET, DOCUMENT_ID):
        print(f"Successfully uploaded {FILE_PATH} to S3")
        
        # Call KYC API
        api_response = call_kyc_api(USER_ID, DOCUMENT_ID)
        if api_response:
            #print("KYC API Response:")
            print(api_response)
            #r = json.loads(api_response['analysis'])
            #print(json.dumps(api_response['message'], indent=2))
            print(api_response['analysis'])
    else:
        print("Failed to upload file to S3. KYC process aborted.")

if __name__ == "__main__":
    main()