# How to retire a content schema

Once you're sure that a schema isn't being used any more (ie you've checked that there are no content items
of this type, and the publishing app that publishes them has had the relevant code removed), follow these
steps to retire it:

1. Delete the jsonnet file from `/content_schemas/formats`

1. Delete any shared definitions that are not used by any of the remaining formats

1. Delete the schema's folder, if one exists, from `/content_schemas/examples`

1. Remove the schema from `/content_schemas/allowed_document_types.yml`

1. Validate/rebuild the other schemas with the following rake task:

   ```sh
   bundle exec rake build_schemas
   ```

   > This step will also validate the examples against the schema.

1. You may also need to remove the parser from content-data-admin ([Example PR](https://github.com/alphagov/content-data-api/pull/2387))
