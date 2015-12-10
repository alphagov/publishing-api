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

  1. Deduplicate draft and live content items

  `bundle exec rake data_hygiene:content_items:deduplicate`


  2. Generate content ids for draft content items

  `MONGODB_URI=mongodb://localhost/draft_content_store_development bundle exec rake data_hygiene:generate_content_id`


  3. Reuse/generate content ids where missing the live content store

  `bundle exec rake data_hygiene:reuse_content_id IMPORT_PATH=./tmp/generated_content_ids.txt`


  4. Generate public_updated_at timestamps where missing in both content stores

  `bundle exec rake data_hygiene:assign_public_updated_at`

  `MONGODB_URI=mongodb://localhost/draft_content_store_development bundle exec rake data_hygiene:assign_public_updated_at`


  5. Fix base_paths with missing locale suffix

  `bundle exec rake data_hygiene:locale_base_path_cleanup:cleanup`

  `MONGODB_URI=mongodb://localhost/draft_content_store_development bundle exec rake data_hygiene:locale_base_path_cleanup:cleanup`


  6. Make a note of the created_at timestamp of the last Event recorded in the publishing-api


  7. Perform a data export from the live content store

  `bundle exec rake data_hygiene:export_content_items:all`


  8. Resolve content_id mismatches between draft and live content stores using the exported data from step 8

  `MONGODB_URI=mongodb://localhost/draft_content_store_development bundle exec rake data_hygiene:draft_content_id_cleanup:cleanup FILE_PATH=./tmp/content_items_2015-12-xx_xx-xx-xx.json`


  9. Perform a data export from the draft content store

  `MONGODB_URI=mongodb://localhost/draft_content_store_development bundle exec rake data_hygiene:export_content_items:all`


  **Note** The following steps need to be performed against a reset publishing api database:

  1. Perform a data import from the live data dump into the publishing api

  `bundle exec rake import_content_items[./../content-store/tmp/content_items_2015-12-xx_xx-xx-xx.json,'live']`

  2. Perform a data import from the draft data dump into the publishing api

  `bundle exec rake import_content_items[./../content-store/tmp/content_items_2015-12-xx_xx-xx-xx.json,'draft']`



  3. Perform a data export from the live publishing api for events since the timestamp noted in step 6) using the rake task here:     https://github.com/alphagov/publishing-api/blob/master/lib/tasks/events.rake

  **Note**: This should be carried out at a quiet time when the publishing api is not
receiving traffic (weekend?).

  4. Re-apply the events to the local publishing api from the file generated in
step 8) using the rake task here: https://github.com/alphagov/publishing-api/blob/master/lib/tasks/events.rake

  5. Backup the live publishing api database

  6. Perform a sql dump of the local publishing api database and replace the live
publishing api with this via a sql load
