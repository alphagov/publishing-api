# Adding a new content schema

Follow these steps to add a new schema:

1. Create a file in `formats` named after your schema with a jsonnet extension (e.g. for a `case_study` you'd create `./content_schemas/formats/case_study.jsonnet`). The file should have the following contents:

   ```json
   (import "shared/default_format.jsonnet") + {
   }
   ```

1. Add the fields required to this file.

   > You could use the contents of the `formats/_example.jsonnet` or other existing schemas as the basis of what to put into the file.
   >
   > See [this PR](https://github.com/alphagov/publishing-api/commit/f657d06ba43fcf720fad43b504692e8793bddde4) for an example of how a new format has previously been added.

1. Add the new format to `./content_schemas/allowed_document_types.yml`.

1. Add a set of curated examples. These examples will be validated against the schema and can also be used by the corresponding frontend applications to verify that it can render examples of the schema. These examples should be added to the `./content_schemas/examples/FORMAT_NAME/frontend` folder.

1. Generate the corresponding schemas with the following rake task:

   ```sh
   bundle exec rake build_schemas
   ```

   > This step will also validate the examples against the schema.

1. Add the schema to Content Data API.

   To ensure new content schema text can be parsed by Content Data API, it needs to be added to an  appropriate [Edition Content Parser](https://github.com/alphagov/content-data-api/tree/main/app/domain/etl/edition/content/parsers) or a new parser should be created. This ensures that content quality metrics such as word count or reading time are available in [Content Data](https://content-data.publishing.service.gov.uk).

   [Example of adding a new content schema to the Content Body parser](https://github.com/alphagov/content-data-api/pull/1906).

   Failing to do so, will cause `Etl::Edition::Content::Parser::InvalidSchemaError` in Content Data API but basic metrics will still be available in Content Data.
