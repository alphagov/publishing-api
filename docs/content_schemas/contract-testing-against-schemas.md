# Contract Testing against Schemas

When changes are made to govuk-content-schemas, the test suite of each of the [dependent apps](https://github.com/alphagov/govuk-content-schemas/blob/aad248a867e878a496dcb488a4ba2170cebdb86b/Jenkinsfile#L7-L38) is run against that branch, to ensure that any changes are compatible.

This method of contract testing is different to our usual [Pact tests](https://docs.publishing.service.gov.uk/manual/pact-broker.html).

## Background

govuk-content-schemas contract testing was proposed in [RFC 4](https://gov-uk.atlassian.net/wiki/display/WH/RFC+4+%3A+Enabling+the+independent+iteration+of+formats+on+government-frontend) and described in the GOV.UK blog post "[Validating a distributed architecture with JSON Schema](https://gdstechnology.blog.gov.uk/2015/01/07/validating-a-distributed-architecture-with-json-schema/)".

We wanted to be able to evolve our publishing systems and have confidence that the changes we make will not break something. We could do this by running all the systems at the same time and testing end-to-end, but setting up such a configuration would be tricky, and keeping it working reliably in a reproducible way which avoids test interference would be very difficult.

The idea of contract testing is to gain more confidence that the whole system works together properly, but without needing to run all the services at the same time. Instead we can test each service in isolation using a 'contract' which describes the expectations on each interacting service.

## How govuk-content-schemas contract testing works

Publishing involves three systems and two representations:

```
[publishing app] ------> [publishing api/content store] ------> [frontend app]
```

The first arrow is the "publishing representation", and the second arrow is the "frontend representation". The latter is more detailed than the former, as the `links` hash is expanded so
that it contains full details about links, wheras the publisher representation
only contains content ids (for full info see [frontend_schema_generator.rb](../lib/schema_generator/frontend_schema_generator.rb)).

This comprises three things:

1. json-schema files which define the *publishing representation* for a given format
2. a curated set of frontend examples of that format, which are validated against the schemas
3. [a mechanism to convert from the 'publisher' schemas to the 'frontend' schemas](https://github.com/alphagov/govuk-content-schemas/blob/main/lib/schema_generator/frontend_schema_generator.rb), simulating the behaviour of the content store

With those three parts we are able to verify the examples against the schemas.

This means that if the frontend works ok with the curated examples, and if the publishing tool produces output which matches the schema, then we can be quite confident that the frontends will work with the data produced by the publishing tool.

## Adding govuk-content-schemas contract tests to your app

You will need to provide tests in your app which are part of the full test suite, but can also be run separately from the other tests (unless your test suite is really fast and likely to stay fast). What you need to do differs depending upon the type of app.

### Frontend apps

You should include tests which use the examples from the govuk-content-schemas to test whether your frontend works or not. [govuk_schemas](https://github.com/alphagov/govuk_schemas) provides code for doing this.

Ideally you should have a test which checks your app against every example for the formats it supports dynamically - so that examples added later are still tested in your app - there is an example in the [govuk_schemas](https://github.com/alphagov/govuk_schemas) README.

### Publishing apps

You should include tests which generate the JSON your app would send to content-store and validate them against the schemas. [govuk_schemas](https://github.com/alphagov/govuk_schemas) provides RSpec and test-unit helpers for this.
