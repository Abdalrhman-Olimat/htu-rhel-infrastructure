#!/bin/bash

# Backup script for HTU Enterprise
# Archives /company and uploads to AWS S3

# Configuration
SOURCE_DIR="/company"
BACKUP_DIR="/tmp"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="backup_$TIMESTAMP.tar.gz"
S3_BUCKET="YOUR_BUCKET_NAME_HERE"



# 1. Create Archive
echo "Compressing $SOURCE_DIR..."
tar -czf "$BACKUP_DIR/$BACKUP_FILE" "$SOURCE_DIR" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Error: Compression failed."
    exit 1
fi

# 2. Upload to S3
echo "Uploading to s3://$S3_BUCKET/..."
aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "s3://$S3_BUCKET/"

if [ $? -eq 0 ]; then
    echo "Upload Successful."
    # 3. Cleanup
    rm -f "$BACKUP_DIR/$BACKUP_FILE"
    echo "Local cleanup complete."
else
    echo "Error: Upload to S3 failed."
    exit 2
fi