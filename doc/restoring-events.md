# Restoring events from S3

To save space, the `payload` column in the `events` table is regularly archived to S3.

This happens using a Jenkins job:

<https://deploy.publishing.service.gov.uk/job/Publishing_API_Archive_Events/>

The job runs every week and archives the payloads older than a month.

The archiving process exports the events to a CSV and puts that in a gzipped file named after the last date of the events, like `2015-12-12T00:00:00+00:00.csv.gz`.

## Restoring payloads

There are a number of ways to restore the payloads.

### 1. Local restore

If you don't want to restore the events on the server, you can do a local restore.

First, download all the files to the server:

```sh
ssh publishing-api-1.production
sudo -u deploy govuk_setenv publishing-api rake download_archive_files
tar czvf events.tgz tmp/events/
```

On your local machine:

```sh
scp publishing-api-1.production:/var/apps/publishing-api/events.tgz .
tar xzvf events.tgz
bundle exec rake import_local_archives
```

There are many events, so it may be worth it to restore just a subset. For example,
you can temporarily modify the `Events::S3Importer` class to just restore actions
with a certain `action`:

```ruby
if row["action"] == "PatchLinkSet" && row["payload"].match("taxons")
  event = Event.find_or_initialize_by(id: row["id"])
  if event.payload.present?
    print 'o'
    next
  end
...
```

### 2. Restore if you know the file

To restore the payloads in the file `events/2015-12-12T00:00:00+00:00.csv.gz`:

```
EVENT_LOG_AWS_ACCESS_ID=AKIAIOSFODNN7EXAMPLE \
EVENT_LOG_AWS_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
EVENT_LOG_AWS_BUCKETNAME=govuk-publishing-api-event-log-integration \
S3_EXPORT_REGION=eu-west-1 \
rake 'events:import_from_s3[events/2015-12-12T00:00:00+00:00.csv.gz]'
```
