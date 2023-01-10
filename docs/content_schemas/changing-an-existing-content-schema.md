# Changing an existing content schema

## General workflow

* create a branch
* make changes to the relevant schema fragment under `formats/<format name>.jsonnet`
* change the relevant frontend examples (or add a new example)
* run `rake build_schemas` to compile a new schema.json
* run `rake` to test the example against the schema
* commit and push
* open a PR
* watch the multi-build status to see if all apps are compatible with the change
* if the builds are successful, it can be merged

## Adding a new field to a content schema

Follow the General workflow described above. You are now free to add support for the field to apps. If you are adding a mandatory field you will need to additionally:

* deploy the publishing app with changes to always populate the field
* populate the field in any records inside content-store
* follow the General workflow, adding the field to the `required` attribute
* you can then update the frontend app to expect the field to always be present

For example, imagine that you need to add a new optional field to the details hash of the `case_study` schema. The steps would be:

1. edit [`formats/case_study.jsonnet`](/formats/case_study.jsonnet) to
   add the new optional field
1. run `rake`. This will:
  1. regenerate the publisher [`schema.json`](/dist/formats/case_study/publisher/schema.json) to incorporate the changes you made to the `details`
  1. regenerate the notification [`schema.json`](/dist/formats/case_study/notification/schema.json) to incorporate the changes
  1. regenerate the frontend [`schema.json`](/dist/formats/case_study/frontend/schema.json) to incorporate the same changes
  1. revalidate all example files to check if they are still valid after this change. This will pass, because the new field is optional
1. [Optional step] you could add an additional example to illustrate how your new field should be used. You can add a new file in [examples/case_study/frontend](/examples/case_study/frontend)
1. create a new branch and commit and push your changes.
   This will run a branch build of govuk-content-schemas.
   This includes running the contract tests for each application which relies on the schemas.
   You'll get immediate feedback about whether publishing applications generate content items compatible with the new schema.
1. once the tests pass, someone will merge your pull request and the new schemas will be available to use
1. Deploy your changes (see [`docs/deployment.md`](deployment.md) for details).

## Removing a field from a content schema

If the field was mandatory:

* Remove the field from the `required` attribute by following the General workflow
  * Remove the field from examples to ensure that the frontend can handle the field being optional
* Deploy any frontend changes
* Change the publisher to stop sending the field
* Deploy the publisher
* Optional: change the records in content-store
* Remove the field by following the General workflow
