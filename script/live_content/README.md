# Checking parity of GraphQL and Content Store responses

A number of scripts are available to check the parity of GraphQL and Content
Store responses.

## Comparing frontend responses

These scripts compare the HTML output from frontend applications.

> If diffing in the development environment, you'll need to start all the relevant
> servers in GOV.UK Docker: Publishing API, Content Store, plus any required
> frontend apps and their dependencies (e.g. Collections, Frontend, Government
> Frontend, Static).

### One document

```sh
./script/live_content/diff_frontend
```

The script has a interactive interface and will prompt for:

- whether to download the HTML (or use a locally cached version)
- the base path of the document to check
- the environment (development, integration, staging or production)
- if integration is selected: basic auth username and password
- the diff output style

### List of documents

```sh
./script/live_content/bulk_diff_frontend --base-paths-file-path path/to/file --environment p
```

For this bulk script, you'll need to prepare a file with a list of base paths
(e.g. `/world`) and an empty line at the end. See the "Retrieving base paths"
section for two ways to do this.

Diffs will be output to `tmp/diffs` by default. Run the script
with `--help` for information on all the required and optional arguments.

## Comparing content items to GraphQL responses

These scripts compare the content item in Content Store to the output from
GraphQL.

> These only operate on the local development stack.

### One document

```sh
./script/live_content/diff base-path-of-document
```

Give the base path of the document as an argument to the script.

### List of documents

```sh
./script/live_content/bulk_diff
```

For this bulk script, you'll need to prepare a file with a list of base paths
(e.g. `/world`) and an empty line at the end. See the "Retrieving base paths"
section for two ways to do this. This file must be saved as
`tmp/base_paths/filtered_base_paths`.

The diff will be shown for each base path and you will be given an option of
moving on or aborting after each one.

## Known issues

### Issue with Bash version

If you get a syntax error when running the diffing scripts, you might be using
an old version of Bash. At the time of writing, the version of Bash shipped with
macOS is two major versions behind the latest release and missing some features
used in the scripts. You can
[install a modern version via Homebrew](https://formulae.brew.sh/formula/bash).

## Retrieving base paths

### From a local Publishing API database

If you have a replicated database locally (including in GOV.UK Docker), there
are a couple of scripts you can use to generate a list of base paths.

#### One per document type

You can generate a list of one base path per document type per existing
GraphQL query (i.e. per schema name). This approach is useful for a quick
diff or to test changes to the diffing scripts

```sh
# prepend with govuk-docker-run for GOV.UK Docker
bundle exec rails runner script/live_content/generate_base_paths.rb
```

#### Up to 1000 per schema name

You can get a random sample of base paths - alongside content IDs and locales,
useful for representing downstream - for a set of schema names. This script will
only include base paths for editions that are live and not unpublished, and a
maximum of 1000 per schema name.

```sh
# prepend with govuk-docker-run for GOV.UK Docker
./script/get_sample first_schema_name second_schema_name
```

### From logs using Athena

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
