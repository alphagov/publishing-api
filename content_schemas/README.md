# GOV.UK content schemas

This directory contains [JSON Schema](http://json-schema.org/) files and examples of the content that uses them on GOV.UK.

The actual JSON schema files live in `dist` and are generated from [Jsonnet templates](https://jsonnet.org) in `source`. Using templates makes it easier to duplicate common blocks across multiple schemas e.g. format and URL fields. **Do not edit files in `dist` manually**, as they will be overwritten.

## Nomenclature

Schemas and examples are divided into three categories:

* `publisher_v2` - for when a publishing application transmits data to the content store
* `frontend` - for data returned by the content store for a frontend application request
* `notification` - for broadcasting messages about content items on the message queue

## Technical documentation

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the tests with all the necessary dependencies. Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

**Use GOV.UK Docker to run any commands that follow.**

### Building the schemas

Use this to validate a change to the schemas, without having to run the tests.

```
bundle exec rake build_schemas
```

### Further documentation

* [How to change an existing content schema](docs/changing-an-existing-content-schema.md)
* [How to add a new content schema](docs/adding-a-new-schema.md)
* [Working with JSON Schema keywords](docs/working-with-json-schema-keywords.md)
* [Contract testing against govuk-content-schemas](docs/contract-testing-against-schemas.md)

## Licence

[MIT Licence](LICENCE)
