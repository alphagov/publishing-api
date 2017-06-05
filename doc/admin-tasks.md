# Admin Tasks

This is a place to list all of the admin tasks available in Publishing API.

## Discarding drafts

If you need to discard a draft of a document, run the `discard_draft` rake task:

```
bundle exec rake discard_draft['some-content-id']
```

## Representing data downstream

Sometimes you need to re-send content to the Content Store to ensure consistency.

The following tasks will allow you to specify which content items/editions to add to the queue that updates the Content Store.

* Represent all editions downstream
```
bundle exec represent_downstream:all
```
N.B. This task will take several hours and should be used with caution.

* Represent downstream for a specific document_type
```
bundle exec represent_downstream:document_type['a-document-type']
```

* Represent downstream for a rendering application
```
bundle exec represent_downstream:rendering_app['application-name']
```

* Represent downstream for a publishing application
```
bundle exec represent_downstream:publishing_app['application-name']
```

* Represent downstream content which has at least one link of type `taxon`
```
bundle exec represent_downstream:tagged_to_taxon
```

* Represent an individual edition downstream
```
bundle exec represent_downstream:content_id['some-content-id']
```

* Represent multiple editions downstream
```
bundle exec represent_downstream:content_id['some-content-id some-other-content-id']
```
N.B. The content ids are separated by a space.
