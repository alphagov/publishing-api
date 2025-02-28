# Adding a new content schema

Create a file in `formats` named after your schema with a jsonnet extension.
Eg for a case_study you'd create formats/case_study.jsonnet

With the following contents:
```
(import "shared/default_format.jsonnet") + {
}
```

You can then use the contents of the `formats/_example.jsonnet` as the basis
of what to put into the file.

Once you have completed these file add the new format to `allowed_document_types.yml`.
You can generate the corresponding schemas with the
[`rake` task](../README.md#Rakefile).

## Sample PR adding a new content schema

- [Adding Content Block Email Address](https://github.com/alphagov/publishing-api/commit/f657d06ba43fcf720fad43b504692e8793bddde4)

## Examples

Any new schema should also ship with a set of curated examples. These examples
will be validated against the schema and can also be used by the corresponding
frontend applications to verify that it can render examples of the schema. These
examples should be added to the `examples/FORMAT_NAME/frontend` folder.

## Ensure new content schema text can be parsed by Content Data API

To ensure new content schema text can be parsed by Content Data API, it needs to be added to an  appropriate [Edition Content Parser](https://github.com/alphagov/content-data-api/tree/main/app/domain/etl/edition/content/parsers) or a new parser should be created. This ensures that content quality metrics such as word count or reading time are available in [Content Data](https://content-data.publishing.service.gov.uk).

[Example of adding a new content schema to the Content Body parser](https://github.com/alphagov/content-data-api/pull/1906). 

Failing to do so, will cause `Etl::Edition::Content::Parser::InvalidSchemaError` in Content Data API but basic metrics will still be available in Content Data.
