# Checking parity of GraphQL and Content Store responses

A couple of scripts are available to check the parity of GraphQL and Content
Store responses:

- `script/live_content/diff_frontend` - this will guide you through diffing the
  responses for one page.
- `script/live_content/bulk_diff_frontend` - this allows you to diff multiple
  pages in one process.

  For the bulk script, you'll need to prepare a file with a list of base paths
  (e.g. `/world`) and an empty line at the end. See the "Retrieving base paths
  from logs using Athena" section for one way to do this.

  Diffs will be output to `tmp/diffs` by default. Run the script
  with `--help` for information on all the required and optional arguments.

If diffing in the development environment, you'll need to start all the relevant
servers in GOV.UK Docker: Publishing API, Content Store, plus any required
frontend apps and their depenedencies (e.g. Collections, Frontend, Government
Frontend, Static).

## Issue with Bash version

If you get a syntax error when running the diffing scripts, you might be using
an old version of Bash. At the time of writing, the version of Bash shipped with
macOS is two major versions behind the latest release and missing some features
used in the scripts. You can
[install a modern version via Homebrew](https://formulae.brew.sh/formula/bash).

## Retrieving base paths from logs using Athena

You can use
[Athena](https://docs.publishing.service.gov.uk/manual/query-cdn-logs.html) to
retrieve base paths of cache misses over a given time period. Below is an
example Trino SQL query. You just need to edit the dates.

Save the output to `tmp/base_paths/unfiltered_base_paths` and then run the
`script/filter_base_paths` script to filter the base paths by one or more schema
names in preparation for running the bulk script. You will need a replicated
Publishing API or Content Store database for this script to work properly. If
using Content Store, pass the `--with-content-store` flag to the script.

```sql
SELECT DISTINCT
  REPLACE(
    SPLIT_PART("url", '?', 1),
    '//',
    '/'
  ) AS "url_path"
FROM
  "fastly_logs"."govuk_www"
WHERE
  "date" = 6
  AND "month" = 5
  AND "year" = 2025
  AND (
    "request_received"
    BETWEEN TIMESTAMP '2025-05-06 12:00'
    AND TIMESTAMP '2025-05-06 17:00'
  )
  AND "content_type" LIKE 'text/html%'
  AND "method" = 'GET'
  AND "status" = 200
  AND "fastly_backend" = 'origin'
  AND "cache_response" = 'MISS'
  AND LOWER("user_agent") NOT LIKE '%bot%'
  AND LOWER("user_agent") NOT LIKE '%crawler%'
  AND LOWER("user_agent") NOT LIKE '%engine%'
  AND LOWER("user_agent") NOT LIKE '%google%'
  AND LOWER("user_agent") NOT LIKE '%java%'
  AND LOWER("user_agent") NOT LIKE '%lua%'
  AND LOWER("user_agent") NOT LIKE '%python%'
  AND LOWER("user_agent") NOT LIKE '%ruby%'
  AND LOWER("user_agent") NOT LIKE '%spider%';
```
