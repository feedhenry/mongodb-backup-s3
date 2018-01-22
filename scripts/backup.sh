#!/bin/bash
# Script for backing up MongoDB data and pushing to S3

# Parameters
HOST=$1
PORT=$2
USER=$3
PASSWORD=$4
AUTH_DB=$5
S3_BUCKET_NAME=$6

# Retrieve a list of all databases
DATABASES=$(mongo $HOST:$PORT/admin -u $USER -p $PASSWORD --eval  "printjson(db.adminCommand('listDatabases'))" | grep name | cut -d '"' -f4 | grep -v local)

# For each database archive data and push directly to S3
for DATABASE in $DATABASES; do
  echo "Dumping database $DATABASE to S3 bucket $S3_BUCKET_NAME..."
  mongodump -h $HOST:$PORT -u $USER -p $PASSWORD -d $DATABASE --archive --gzip --authenticationDatabase $AUTH_DB | aws s3 cp - s3://$S3_BUCKET_NAME/backups/mongodb/$(date '+%Y-%m-%d')/$DATABASE-$(date '+%H:%M:%S').dump.gz
done
