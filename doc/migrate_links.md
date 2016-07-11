#Migrate links
Currently we have migrated_links and links in the content store

We need to swap them over so we need to represent them downstream to the
content_store we also need to ensure that there are no differences between the
two so that we don't introduce breaking changes.

Current steps to migrate a document_type over to using the migrating_links:

1: Compare expanded_links and link in content_store:
   run `rake 'compare:schema_name[topical_event_about_page]'`
   ##note the compare:schema_name is technically incorrect, it should be
   document_type, but having made the change to the rake task

   This will generate output like:
   ```
    DIFF b6a150f1-52b1-4832-a12d-b432f78f7209 ********************
    [["-", "parent[0].details", {"start_date"=>"2016-02-22T00:00:00.000+00:00",
         "end_date"=>"2016-06-23T00:00:00.000+00:00"}],
    ```
   this says that the expanded links is missing
   'parent.details' in the first element of the array.
   Suggesting that that document_type is missing the details field on that
   document_type: In the publishing API add any custom fields to
   `Queries::DependeeExpansionRules#custom`

   To investigate a particular content_item in more detail run:
   rake 'compare:content_item[:content_id]'

   We need to investigate any differences, but in general there should be few.

2: Once we are satisfied that there are no differences we can run the rake task
   in the publishing api to represent the document_type over to the content_store:

   Move the document_type that you want to migrate over into
   `Presenters::MigrateExpandedLinks#document_types`
   run `rake migrate_links:document_type[document_type]`

   This need to be run on production too when it has been merged and deployed.
   But the expanded_links and the links can interoperate, but it is best to
   makes sure that the document_type has been fully migrated.

# locally

Because there have been a few changes recently, the expanded_links will be
outdated. What I do is:

Delete the content_items in the content_store for a document type
In the publishing api run in a rails console
`Commands::V2::RepresentDownstream.new.call(ContentItem.where(document_type: document_type))`
this will ensure that everything is up to date in the content store.

Then run the rake task in the content store to compare the differences.
run `rake 'compare:schema_name[document_type]'`

Then when I make any nessesary changes I continue with step 2.

# other useful things to look at:

https://github.com/alphagov/publishing-api/pull/403/files
https://github.com/alphagov/publishing-api/blob/master/app/presenters/downstream_presenter.rb#L44

