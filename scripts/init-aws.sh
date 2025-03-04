#!/bin/bash
# Wait for LocalStack to be fully initialized
sleep 10
# Create the S3 bucket
awslocal s3 mb s3://arroyo
# Exit with success
exit 0
