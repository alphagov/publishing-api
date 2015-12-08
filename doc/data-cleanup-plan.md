# Data Cleanup Plan: 8th December, 2015

Currently, there is data in the content store that is not accurately reflected
in the publishing api. This is largely due to the publishing api being under
development at the time that this data was pushed through the system.

## Overview

In simple terms, the plan is to fix some data problems with content store and
then use this to rebuild the publishing api from scratch. The live publishing
api database will then be swapped out for the newly built one.

This is made more complicated by the fact that the publishing api is under
constant usage and so there are some steps towards the end to ensure that any
requests that came in whilst the system was rebuilding are re-applied.

## Steps

This outlines the steps that we plan to take to remedy this situation:

1) Fix the HMRC content id issues in draft and live content store using the
migration here: https://github.com/alphagov/content-store/blob/master/db/migrate/20151207120531_update_blank_hmrc_manuals_content_ids.rb

2) De-duplicate content items in draft and live content stores using the
rake task here: https://github.com/alphagov/content-store/blob/master/lib/tasks/data_hygiene/content_item_deduplicator.rake

3) Generate content ids where missing in the draft content store using the rake
task here: https://github.com/alphagov/content-store/blob/data-cleanup/lib/tasks/data_hygiene/missing_attributes.rake

4) Reuse/generate content ids where missing the live content store using the
rake task here: https://github.com/alphagov/content-store/blob/data-cleanup/lib/tasks/data_hygiene/missing_attributes.rake

**Note**: This task relies in the output file from step 3).

5) Generate public_updated_at timestamps where missing in both content stores
using the rake task here: https://github.com/alphagov/content-store/blob/data-cleanup/lib/tasks/data_hygiene/missing_attributes.rake

6) Perform a data export from the draft and live content stores using the rake
task here: https://github.com/alphagov/content-store/blob/data-cleanup/lib/tasks/data_hygiene/export_data.rake

**Note**: At the point that this task begins, it is important that a note be made of
the latest event's timestamp in the publishing api. This will be used later to
re-apply events that were applied after the data dump was initiated.

7) Perform a data import from the draft and live data dumps into the publishing
api using the rake task here: https://github.com/alphagov/publishing-api/blob/master/lib/tasks/import_data.rake

**Note**: This should be applied against a clean database. It should not be applied
against the live database as it takes a significant amount of time to run.

8) Perform a data export from the live publishing api for events since the
timestamp noted in step 6) using the rake task here: https://github.com/alphagov/publishing-api/blob/master/lib/tasks/events.rake

**Note**: This should be carried out at a quiet time when the publishing api is not
receiving traffic (weekend?).

9) Re-apply the events to the local publishing api from the file generated in
step 8) using the rake task here: https://github.com/alphagov/publishing-api/blob/master/lib/tasks/events.rake

10) Backup the live publishing api database

11) Perform a sql dump of the local publishing api database and replace the live
publishing api with this via a sql load
