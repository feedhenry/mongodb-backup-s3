## Getting Started Guide: MongoDB

### Amazon S3
Both jobs mentioned below will store MongoDB data archives in an S3 bucket specified by the ```AWS_S3_BUCKET_NAME``` parameter. This bucket **must** exist before running the templates. Once the archive has been pushed to S3, the directory structure generated uses the following convention:
```
Amazon S3 >> AWS_S3_BUCKET_NAME >> backups >> mongodb >> YYYY-MM-DD >> DATABASE_NAME-H:M:S.dump.gz
```

### Openshift Job Template
The mongodb-backup-s3-job-template.yaml file provides an [Openshift Job template](https://docs.openshift.com/container-platform/3.6/dev_guide/jobs.html) which iterates over all databases in a specified MongoDB instance, archives these databases and streams them directly to Amazon S3 without having to store the archives locally.

#### Usage
The job template requires a number of parameters to be specified. These can be viewed by using the ```oc process command```. See below:
```
$ oc process --parameters -f mongodb-backup-s3-job-template.yaml
NAME                              DESCRIPTION                                                           GENERATOR           VALUE
AWS_ACCESS_KEY_ID                 AWS Access Key ID
AWS_SECRET_ACCESS_KEY             AWS Secret Access Key
AWS_S3_BUCKET_NAME                Name of an existing Amazon S3 bucket where backups are to be pushed
BACKUP_IMAGE                      Backup docker image URL                                                                   docker.io/rhmap/backups
BACKUP_IMAGE_TAG                  Backup docker image tag                                                                   latest
MONGODB_HOST                      MongoDB host to target
MONGODB_PORT                      MongoDB port number                                                                       27017
MONGODB_USER                      MongoDB user to perform the backup
MONGODB_PASSWORD                  MongoDB user password
MONGODB_AUTHENTICATION_DATABASE   MongoDB database to authenticate against                                                  admin
GPG_RECIPIENT                     GPG recpient name to be used to encrypt the database archive
GPG_PUBLIC_KEY                    GPG public key content (base64 encoded)
GPG_TRUST_MODEL                   GPG encryption trust model, defaults to "always"                                          always
```

#### Running the Job
The job template can be run directly using the Openshift CLI or made available through the OpenShift Service Catalog.

##### OC Command line tool
```
$ oc new-app mongodb-backup-s3-job-template.yaml -p AWS_ACCESS_KEY_ID=<aws_access_key_id> -p AWS_SECRET_ACCESS_KEY=<aws_secret_access_key> -p AWS_S3_BUCKET_NAME=<bucket_name> -p MONGODB_USER=admin -p MONGODB_PASSWORD=<mongodb_admin_password> -p MONGODB_HOST=<mongodb-host> -p MONGODB_AUTHENTICATION_DATABASE=admin -p GPG_RECIPIENT=admin@admin.com -p "GPG_PUBLIC_KEY=$(cat keys_public.gpg | base64)"
```

###### Validation
Retrieve the name of the newly generated backup job pod:
```
$ oc get pods
```
View the logs of the backup job pod to ensure that the job has run successfully
```
$ oc logs <pod-name>
Dumping database mydatabase to S3 bucket my-s3-bucket...
2018-01-22T20:00:09.541+0000	writing mydatabase.audit_log to archive on stdout
2018-01-22T20:00:09.547+0000	done dumping mydatabase.audit_log (6 documents)
```

###### Remove the Job
```
$ oc delete job mongodb-backup-s3-job
```

###### Remove the Secret
There is a secret bound to a job when it is initiated. Therefore, when the job to removed, the secret must also be removed to maintain consistency.
```
oc delete secret mongodb-backup-s3-secret
```

##### Service Catalog
###### Create Template and make available through the Service Catalog
Specify the project where you want the job to run from:
```
$ oc project <project_name>
```
Create the template inside the target project:
```
$ oc create -f mongodb-backup-s3-job-template.yaml
> template "mongodb-backup-s3-job-template" created
```
* Login to the Openshift console and navigate to the target project
* Select <span style="color:green">Add to Project</span> dropdown in the top Nav menu and click <span style="color:green">Browse Catalog</span>
* In the next screen select the <span style="color:green">Uncategorized</span> option listed under the <span style="color:green">Technologies</span> header
* Find the template named <span style="color:green">mongodb-backup-s3-job-template</span> and click the select button
* Fill out all parameters with relevant values and click the Create button to create the job
* Validate that the job ran successfully by viewing the logs of the newly generated backup job pod

### Openshift CronJob Template
The mongodb-backup-s3-cronjob-template.yaml file provides an [Openshift CronJob template](https://docs.openshift.com/container-platform/3.6/dev_guide/cron_jobs.html) which iterates over all databases in a specified MongoDB instance, archives these databases and streams them directly to Amazon S3 on a scheduled basis.

**NOTE**: Openshift CronJobs remain a technology preview feature and are not suitable for production use.

#### Usage
The cronjob template requires a number of parameters to be specified. These can be viewed by using the ```oc process command```. See below:
```
$ oc process --parameters -f mongodb-backup-s3-cronjob-template.yaml
NAME                              DESCRIPTION                                                           GENERATOR           VALUE
AWS_ACCESS_KEY_ID                 AWS Access Key ID
AWS_SECRET_ACCESS_KEY             AWS Secret Access Key
AWS_S3_BUCKET_NAME                Name of an existing Amazon S3 bucket where backups are to be pushed
CRON_SCHEDULE                     Job schedule in Cron Format [Default is everyday at 2am]                                  0 2 * * *
BACKUP_IMAGE                      Backup docker image URL                                                                   docker.io/rhmap/backups
BACKUP_IMAGE_TAG                  Backup docker image tag                                                                   latest
MONGODB_HOST                      MongoDB host to target
MONGODB_PORT                      MongoDB port number                                                                       27017
MONGODB_USER                      MongoDB user to perform the backup
MONGODB_PASSWORD                  MongoDB user password
MONGODB_AUTHENTICATION_DATABASE   MongoDB database to authenticate against                                                  admin
GPG_RECIPIENT                     GPG recpient name to be used to encrypt the database archive
GPG_PUBLIC_KEY                    GPG public key content (base64 encoded)
GPG_TRUST_MODEL                   GPG encryption trust model, defaults to "always"                                          always
```

#### Running the CronJob
The cronjob template can be run directly using the Openshift CLI or made available through the OpenShift Service Catalog.

##### OC Command line tool
```
$ oc new-app mongodb-backup-s3-cronjob-template.yaml -p AWS_ACCESS_KEY_ID=<aws_access_key_id> -p AWS_SECRET_ACCESS_KEY=<aws_secret_access_key> -p AWS_S3_BUCKET_NAME=<bucket_name> -p MONGODB_USER=admin -p MONGODB_PASSWORD=<mongodb_admin_password> -p MONGODB_HOST=mongodb-1 -p MONGODB_AUTHENTICATION_DATABASE=admin CRON_SCHEDULE='0 * * * *' -p GPG_RECIPIENT=admin@admin.com -p "GPG_PUBLIC_KEY=$(cat keys_public.gpg | base64)"
```

###### Validation
The cronjob will be executed based on the value of the ```CRON_SCHEDULE``` parameter. If this was set to run every hour for example, the backup pod will not be created and run until the top of the hour.

Check that the CronJob has been created:
```
$ oc get cronjobs
NAME                        SCHEDULE    SUSPEND   ACTIVE    LAST-SCHEDULE
mongodb-backup-s3-cronjob   0 * * * *   False     0         <none>
```

When the job runs (based on the value of the ```CRON_SCHEDULE``` parameter), retrieve the name of the newly generated backup job pod:
```
$ oc get pods
```
View the logs of the backup job pod to ensure that the job has run successfully
```
$ oc logs <pod-name>
Dumping database mydatabase to S3 bucket my-s3-bucket...
2018-01-22T20:00:09.541+0000	writing mydatabase.audit_log to archive on stdout
2018-01-22T20:00:09.547+0000	done dumping mydatabase.audit_log (6 documents)
```

###### Remove CronJob
```
$ oc delete cronjob mongodb-backup-s3-cronjob
```

##### Service Catalog
###### Create Template and make available through the Service Catalog
Specify the project where you want the job to run from:
```
$ oc project <project_name>
```
Create the template inside the target project:
```
$ oc create -f mongodb-backup-s3-cronjob-template.yaml
> template "mongodb-backup-s3-cronjob-template" created
```
* Login to the Openshift console and navigate to the target project
* Select <span style="color:green">Add to Project</span> dropdown in the top Nav menu and click <span style="color:green">Browse Catalog</span>
* In the next screen select the <span style="color:green">Uncategorized</span> option listed under the <span style="color:green">Technologies</span> header
* Find the template named <span style="color:green">mongodb-backup-s3-cronjob-template</span> and click the select button
* Fill out all parameters with relevant values and click the Create button to create the job
* Validate that the job ran successfully by viewing the logs of the newly generated backup job pod
