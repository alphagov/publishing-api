# Definitions

The contents of this directory is autoloaded and merged together when schemas
are generated. Files prefixed with an underscore won't be merged.

You are encouraged to only add definitions here that are used by a number of
schemas and instead define things in the definitions section of a schema.

If you wish to share a definition with a number of schemas you can define a file
in this directory with an underscore prefix and then merge that into your
schemas definitions.

eg
```
(import "shared/default_format.jsonnet") + {
  document_type: "case_study",
  definitions: (import "shared/definitions/_case_study_definitions.json) + {
```

This can reduce namespace collisions and make it easier to know if definitions
are used.

