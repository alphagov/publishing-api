# Data Cleanup Plan: 17th December, 2015

**Update:** This plan was carried out successfully on Thursday 17th, December
2015 at 12.30pm.

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

  `rake data_hygiene:content_items:deduplicate`


  2. Generate content ids for draft content items

  `rake data_hygiene:generate_content_id`


  3. Reuse/generate content ids where missing the live content store

  `rake data_hygiene:reuse_content_id IMPORT_PATH=./tmp/generated_content_ids.txt`


  4. Generate public_updated_at timestamps where missing in both content stores

  **draft content store**

  `rake data_hygiene:assign_public_updated_at`

  **live content store**

  `rake data_hygiene:assign_public_updated_at`


  5. Fix base_paths with missing locale suffix

  **draft content store**

  `rake data_hygiene:locale_base_path_cleanup:cleanup`

  **live content store**

  `rake data_hygiene:locale_base_path_cleanup:cleanup`


  6. Make a note of the created_at timestamp of the last Event recorded in the publishing-api

  `rails runner "puts Event.last.created_at"`


  7. Export all path reservations from the publishing api

  `rake export_path_reservations[tmp/path_reservations.json]`


  8. Perform a data export from the **live content store**

  `rake data_hygiene:export_content_items:all`


  9. Resolve content_id mismatches between draft and live content stores using the exported data from step 8

  `rake data_hygiene:draft_content_id_cleanup:cleanup FILE_PATH=./tmp/content_items_2015-12-xx_xx-xx-xx.json`


  10. Perform a data export from the **draft content store**

  `rake data_hygiene:export_content_items:all`


  **Note** The following steps need to be performed against a reset publishing api database:

  1. Perform a data import from the live data dump into the publishing api

  `rake import_content_items[./../content-store/tmp/content_items_2015-12-xx_xx-xx-xx.json,'live']`

  2. Perform a data import from the draft data dump into the publishing api

  `rake import_content_items[./../content-store/tmp/content_items_2015-12-xx_xx-xx-xx.json,'draft']`

  3. Re-apply the exported path reservations

  `rake import_path_reservations[tmp/path_reservations.json]`

  4. Perform a data export from the live publishing api for events since the timestamp noted in step 6) using the rake task here:     https://github.com/alphagov/publishing-api/blob/master/lib/tasks/events.rake

  **Note**: This should be carried out at a quiet time when the publishing api is not
receiving traffic (weekend?).

  `rake events:export TIMESTAMP="2015-12-11 12:30:00"`


  5. Re-apply the events to the publishing api import from the file generated in
step 8) using the rake task here: https://github.com/alphagov/publishing-api/blob/master/lib/tasks/events.rake

  `rake events:import`


  9. Make a note of the last event timestamp in the publishing api import database

  `rails runner "puts Event.last.created_at"`


  10. Stop the publishing-api application for all backends using fabric scripts

  ```
  fab <env> node_type:backend app.stop:publishing-api
  ```

  11. Make another export of events from the production publishing api database from the timestamp captured 2 steps previously

  `rake events:export TIMESTAMP="2015-12-11 17:30:00"`

  12. Re-apply the events to the publishing api import database to cover any events missed in the major event import replay

  `rake events:import`

  12. Backup the import publishing api database

  ```
  pg_dump -c -C -f publishing_api_import.sql publishing_api_import
  ```

  7. Backup the live publishing api database

  ```
  pg_dump -c -C -f publishing_api_production.sql publishing_api_production
  ```


  10. Rename production and import publishing api databases

  ```
  psql template1

  template1=# select pg_terminate_backend(pid) from pg_stat_activity where datname='publishing_api_production';ALTER DATABASE publishing_api_production RENAME TO publishing_api_production_replaced;select pg_terminate_backend(pid) from pg_stat_activity where datname='publishing_api_import';ALTER DATABASE publishing_api_import RENAME TO publishing_api_production;
  ```

  11. Start the publishing-api backends

  ```
  fab <env> node_type:backend app.start:publishing-api
  ```

