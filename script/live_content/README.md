# Checking parity of GraphQL and Content Store responses

A number of scripts are available to check the parity of GraphQL and Content
Store responses.

## Type of comparison

With the scripts, you can compare:
- the HTML rendered from frontend applications when backed by data from Content
Store versus our GraphQL endpoint
- the JSON content item returned by Content Store versus our GraphQL endpoint

The comparisons default to apps running locally (the development environment).
If you need to run them against a different environment, check the "Using custom
hosts" section.

> Both types of comparison filter out inconsequential diffs such as
> request-specific hashes.

> We generally have a higher tolerance for JSON diffs than HTML diffs, since the
> rendered page is ultimately what users see.

## Preparation

Before running the scripts, you'll need to start all the relevant servers in
GOV.UK Docker: Publishing API, Content Store, plus any required frontend apps
and their dependencies (e.g. Collections, Frontend, Government Frontend,
Static).

It's recommended that you represent content from Publishing API to Content Store
before running any diffs. See the "Syncing Content Store and Publishing API
databases" section for more information.

## Comparing a single document

Give the base path of the document as an argument to the script.

Frontend (HTML):

```sh
./script/live_content/diff_frontend base-path-of-document
```

Content item (JSON):

```sh
./script/live_content/diff base-path-of-document
```

## Comparing a list of documents

For the bulk scripts, you'll need to prepare a file with a list of base paths
(e.g. `/world`) and an empty line at the end. See the "Retrieving base paths"
section for a few ways to do this. This file must be saved as
`tmp/base_paths/filtered_base_paths`.

Diffs - where found - will be shown for each base path and you will be given the
option of moving on or aborting after each one.

Frontend (HTML):

```sh
./script/live_content/bulk_diff_frontend
```

Content item (JSON):

```sh
./script/live_content/bulk_diff
```

## Using custom hosts

You might wish to use a custom hosts for your apps, for example if:
- running the apps locally but without GOV.UK Docker
- running against integration with port-forwarding (see "Comparing documents in
the integration environment")

This is supported in all the diffing scripts. To do this, provide environment
variables with the hosts for all the apps the script will need to hit.

For example:

```sh
PUBLISHING_API_HOST='localhost:8080' \
CONTENT_STORE_HOST='localhost:8081' \
script/live_content/diff
```

```sh
FRONTEND_HOST='localhost:8080' \
GOVERNMENT_FRONTEND_HOST='localhost:8081' \
script/live_content/bulk_diff_frontend
```

## Comparing documents in the integration environment

Sometimes you may wish to use the integration environment to avoid the need to
replicate data locally. To do this, you can create a tunnel into Publishing API
(as it is not accessible to the public).

Log into the integration environment per the ["Access a GOV.UK EKS cluster"
guidance](https://docs.publishing.service.gov.uk/kubernetes/get-started/access-eks-cluster/#access-a-cluster-that-you-have-accessed-before),
or alternatively as a subshell:

```sh
gds aws govuk-integration-developer --shell
```

Then create tunnels to both Publishing API and Content Store (you'll need to
set up each tunnel in a separate shell):

```sh
kubectl -n apps port-forward deployment/publishing-api-read-replica 8080:8080
kubectl -n apps port-forward deployment/content-store 8081:8080
```

Then provide the relevant environment variables to any of the diffing scripts
(see "Using custom hosts"). For example, if the ports have been set up as above,
the Publishing API host will be `localhost:8080` and the Content Store host will
be `localhost:8081`.

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

#### For bulk diffing

You can get a random sample of base paths per document type per schema name,
which is useful for bulk diffs when thoroughly testing GraphQL support. This
script will provide base paths from a large number of published and a few
withdrawn editions for each document type. It will create two files:
- one containing just base paths, ready for diffing
- another including the base path, content ID, locale, schema name, and document
  type of each sampled edition, which can be used for representing editions to
  Content Store (see the "Syncing Content Store and Publishing API databases"
  section) or for getting more details on a diffy base path

```sh
# prepend with govuk-docker-run for GOV.UK Docker
./script/get_sample first_schema_name second_schema_name
```

#### For testing small changes

You can generate a list of one base path per document type per existing
GraphQL query (i.e. per schema name). This approach is useful for a quick
diff or to test changes to the diffing scripts.

```sh
# prepend with govuk-docker-run for GOV.UK Docker
bundle exec rails runner script/live_content/generate_base_paths.rb
```

## Syncing Content Store and Publishing API databases

Even with locally replicated databases from backups made on the same day,
there's no guarantee that data will be in sync between Content Store and
Publishing API. This can cause a lot of noise when diffing Content Store and
Publishing API (GraphQL) responses.

To that end, we have a script that runs through a sample at `script/data/sample`
(the output location of `script/get_sample`) and runs a pared down version of
`Commands::V2::RepresentDownstream`. This will ensure the two databases are in
sync and make meaningful diffs easier to identify.

With the Content Store sever running:

```sh
# prepend with govuk-docker-run for GOV.UK Docker
./script/represent_for_diffing
```
