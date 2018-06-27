#!/bin/bash
# Script for backing up MongoDB data and pushing to S3

# Parameters
HOST=$1
PORT=$2
USER=$3
PASSWORD=$4
AUTH_DB=$5
S3_BUCKET_NAME=$6
GPG_RECIPIENT=$7

DATESTAMP=$(date '+%Y-%m-%d')

# Retrieve a list of all databases
DATABASES=$(mongo $HOST:$PORT/admin -u $USER -p $PASSWORD --eval "rs.slaveOk(); printjson(db.adminCommand('listDatabases'))" | grep name | cut -d '"' -f4 | grep -v local)

# Imports gpg keys
gpg --import /opt/rh/secrets/gpg_public_key
gpg --list-keys

# For each database archive data and push directly to S3
for DATABASE in $DATABASES; do
  TIMESTAMP=$(date '+%H:%M:%S')
  echo "==> Archiving database \"$DATABASE\""
  mongodump -h $HOST:$PORT -u $USER -p $PASSWORD -d $DATABASE --archive --gzip --authenticationDatabase $AUTH_DB > /tmp/$DATABASE-$TIMESTAMP.dump.gz
  echo "==> Encrypting database archive \"$DATABASE\""
  gpg --no-tty --batch --yes --encrypt --recipient "$GPG_RECIPIENT" --trust-model $GPG_TRUST_MODEL /tmp/$DATABASE-$TIMESTAMP.dump.gz
  echo "==> Dumping database $DATABASE to S3 bucket s3://$S3_BUCKET_NAME/backups/mongodb/$DATESTAMP/"
  s3cmd put --progress /tmp/$DATABASE-$TIMESTAMP.dump.gz.gpg s3://$S3_BUCKET_NAME/backups/mongodb/$DATESTAMP/$DATABASE-$TIMESTAMP.dump.gz.gpg
  STATUS=$?
  if [ $STATUS -eq 0 ]; then
    echo "==> Dump $DATABASE: COMPLETED"
  else
    echo "==> Dump $DATABASE: FAILED"
    exit 1
  fi
  echo "==> Cleaning up"
  rm /tmp/$DATABASE-$TIMESTAMP.dump.gz /tmp/$DATABASE-$TIMESTAMP.dump.gz.gpg
  echo "==> Listing archived artifact under S3 dir: s3://$S3_BUCKET_NAME/backups/mongodb/$DATESTAMP/"
  aws s3 ls s3://$S3_BUCKET_NAME/backups/mongodb/$DATESTAMP/ --human-readable --summarize | grep $DATABASE | grep $TIMESTAMP
done
