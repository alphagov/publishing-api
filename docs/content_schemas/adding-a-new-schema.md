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

## Examples

Any new schema should also ship with a set of curated examples. These examples
will be validated against the schema and can also be used by the corresponding
frontend applications to verify that it can render examples of the schema. These
examples should be added to the `examples/FORMAT_NAME/frontend` folder.
