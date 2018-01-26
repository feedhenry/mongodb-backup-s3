#!/bin/bash
# Script for backing up MySQL data and pushing to S3

# Parameters
HOST=$1
USER=$2
PASSWORD=$3
S3_BUCKET_NAME=$4

DATESTAMP=$(date '+%Y-%m-%d')

# Retrieve a list of all databases
DATABASES=$(mysql -h$HOST -u$USER  -p$PASSWORD -e 'SHOW DATABASES' | tail -n+2 | grep -v information_schema)

# For each database archive data and push directly to S3
for DATABASE in $DATABASES; do
  TIMESTAMP=$(date '+%H:%M:%S')
  echo "==> Dumping database $DATABASE to S3 bucket s3://$S3_BUCKET_NAME/backups/mysql/$DATESTAMP/"
  mysqldump -h$HOST -u$USER -p$PASSWORD -R $DATABASE | gzip | aws s3 cp - s3://$S3_BUCKET_NAME/backups/mysql/$DATESTAMP/$DATABASE-$TIMESTAMP.dump.gz
  STATUS=$?
  if [ $STATUS -eq 0 ]; then
    echo "==> Dump $DATABASE: COMPLETED"
  else
    echo "==> Dump $DATABASE: FAILED"
    exit 1
  fi
  echo "==> Listing archived artifact under S3 dir: s3://$S3_BUCKET_NAME/backups/mysql/$DATESTAMP/"
  aws s3 ls s3://$S3_BUCKET_NAME/backups/mysql/$DATESTAMP/ --human-readable --summarize | grep $DATABASE | grep $TIMESTAMP
done
