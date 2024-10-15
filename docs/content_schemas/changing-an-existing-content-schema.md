# Changing an existing content schema

## When not adding or removing top-level fields

This describes how to add or remove fields that extend the top-level fields
defined in `default_format.jsonnet`. For example, if you wanted to submit an
additional field via a form in a publishing app, you might add a field nested
within `details` (a field already defined in `default_format.jsonnet`).

1. If you're adding or removing a required field:
   - Update publishing app(s) to provide/stop providing the field
   - If removing a field, update frontend app(s) to no longer access the
     soon-to-be-removed field
   - Update existing data in Content Store to ensure they conform with the
     incoming schema changes
1. Update the relevant schema fragment under
   `content_schemas/formats/<format_name>.jsonnet`
   - Add or remove the desired `details` > `properties` property
   - If the field is/was required, update the `details` > `required` array
1. If necessary, add, remove or update relevant definition file within
   `content_schemas/formats/shared/definitions` to add or remove the definition
   for the field
1. Add, remove, or update the relevant example schemas in
   `content_schemas/examples/**/<example_name>.jsonnet`
1. Run `rake build_schemas` to compile the updated schemas in
   `content_schemas/dist/` and validate the example schemas
1. Check that all the CI workflows pass. These will verify that the content
   schemas are compatible with the suite of publishing apps

### Non-top-level field examples

- [Adding a new optional field to the `details` property](https://github.com/alphagov/publishing-api/pull/2780/commits/18611f4a7eae7083d8ec4db84c5968fe492fd37b)
- [Adding a new definition](https://github.com/alphagov/publishing-api/commit/ecae69f93d0fdf9b6edf9d45b35844e2c9965520#diff-0dc22d7709c7e0d783753fcb265d78c54c4d332cad274249944ca5cab297398f)
- [Updating a definition](https://github.com/alphagov/publishing-api/commit/cc282faa094e1cc176346b14a6d70b26c5fff120#diff-d3574f44494e19be552aba2ae11deeef2e321821bc8e2d7bac8c6e51408b784b)
- [Requiring a property](https://github.com/alphagov/publishing-api/commit/3d141bd62ef6dcd8e1d0aa0224efaa8893ebb0fa#diff-d95f9261dcdb8098a73d80db7612b378c009f051f8cbbff8a0968ce9bafc665c)

## When adding or removing top-level fields

This describes how to add or remove top-level fields to the default format.
These fields tend to be overridden in `.jsonnet` schemas that extend
`default_format.jsonnet`. This allows you to, among other things, define a
top-level `"forbidden"` field that should not be provided by consumers of the
API, then allow it for schemas further down the chain by marking it as
`"optional"`.

1. If you're adding or removing a required field:
   - Update publishing app(s) to provide/stop providing the field
   - If removing a field, update frontend app(s) to no longer access the
     soon-to-be-removed field
   - Update existing data in Content Store to ensure they conform with the
     incoming schema changes
1. Add/remove the new field in `default_format.jsonnet`, giving it a status of
   `required`, `optional`, `forbidden` or `null`.
1. Add/remove the new definition file for this field type in
   `content_schemas/formats/shared/definitions`. This will need to include a
   definition for the field and a definition for the
   `optional`/`required`/`forbidden` status where relevant. This will be read by
   the `format` code in the next step
1. Add a new method named after this field to `lib/schema_generator/format.rb`
   to have it written to the generated files. This specifies which definition to
   use based on the status specified in `jsonnet` schema
1. Add a new key to the `derived_properties` method's hash to read the value in
   `lib/schema_generator/{publisher_content/frontend/notification}_schema_generator.rb`
   when generating the schema
1. Update any extending `jsonnet` files to override this value by setting a
   different status against this field where required, e.g. to mark a default
   `forbidden` field as `optional` at a lower level
1. Run `rake build_schemas` to compile the updated schemas in
   `content_schemas/dist/` and validate the example schemas
1. Check that all the CI workflows pass. These will verify that the content
   schemas are compatible with the suite of publishing apps

### Top-level property examples

- [Adding a new top-level property](https://github.com/alphagov/publishing-api/commit/cacb7e7b1f8563587f0ee9aa08522b70d4c01b8c)
