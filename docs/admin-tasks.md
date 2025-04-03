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
bundle exec rake represent_downstream:all
```
N.B. This task will take several hours and should be used with caution.

* Represent downstream for a specific document_type
```
bundle exec rake represent_downstream:document_type['a-document-type']
```

* Represent downstream for a rendering application
```
bundle exec rake represent_downstream:rendering_app['application-name']
```

* Represent downstream for a publishing application
```
bundle exec rake represent_downstream:publishing_app['application-name']
```

* Represent an individual edition downstream
```
bundle exec rake represent_downstream:content_id['some-content-id']
```

* Represent an individual edition downstream via the high priority queue
```
bundle exec rake represent_downstream:high_priority:content_id['some-content-id']
```

* Represent multiple editions downstream
```
bundle exec rake represent_downstream:content_id['some-content-id some-other-content-id']
```

* Represent multiple editions downstream via the high priority queue
```
bundle exec rake represent_downstream:high_priority:content_id['some-content-id some-other-content-id']
```

N.B. The content ids are separated by a space.

* Represent documents by document type(s) downstream via the high priority queue
```
bundle exec rake represent_downstream:high_priority:document_type['a-document-type a-document-type']
```

N.B. The document types are separated by a space. This has also been set up as a
[Jenkins job](https://github.com/alphagov/govuk-puppet/blob/master/modules/govuk_jenkins/manifests/jobs/publishing_api_republish_organisations.pp) which will need to be enabled.

## Populating expanded links into database

The [expanded-links endpoint](api.md#get-v2expanded-linkscontent_id) defaults
to accessing denormalised data stored in the database. If there are reasons
that this is now out of sync or data is missing you can populate it with
a couple of rake commands.

It will also be rebuilt any time a piece of content is represented downstream.

* To populate every document (this will take a long time - hours)
```
bundle exec rake expanded_links:populate
```

* To populate every document of a document_type
```
bundle exec rake expanded_links:populate_by_document_type['document-type']
```

* To purge the expanded links cache
```
bundle exec rake expanded_links:truncate
```

## Publishing special routes

Special routes are content items that have to be put into publishing-api / content-store so that routes
can be created for them in router-api's database (this includes things like assets that have to be available
at route or hardcoded pages). The routes are described in lib/data/special_routes.yaml

* To publish the homepage special route
```
bundle exec rake special_routes:publish_homepage
```

* To publish all special routes (except homepage)
```
bundle exec rake special_routes:publish
```

* To publish all special routes for one application
```
bundle exec rake special_routes:publish_for_app[frontend]
```

* To publish one route
```
bundle exec rake special_routes:publish_one_route[/base-path]
```

* To unpublish one route so that it will return Gone
```
bundle exec rake special_routes:unpublish_one_route[/base-path]
```

* To unpublish one route so that it will return Redirect
```
bundle exec rake special_routes:unpublish_one_route[/base-path,/new-base-path]
```

### Adding new special routes

Add an entry to /lib/data/special_routes.yaml, for example:

```
- :content_id: 'c1f08359-21f7-49c1-8811-54bf6690b6a3'
  :base_path: '/account/home'
  :title: 'Account home page'
  :rendering_app: 'frontend'
```

You can generate a new value for `content_id` by running `SecureRandom.uuid` in a ruby console.

## Generating CSV reports of publishings and unpublishing by date range

There are two tasks provided which create CSV reports of publishings and
unpublishings within a given time range. Both task require a `from` timestamp
argument and a `until` timestamp argument.

To see all the editions that were published between two times run:

```
bundle exec rake "csv_report:publishings_by_date_range['2020-10-01 10:00', '2020-12-31 10:00']"
```

To see all the editions that were unpublished between two times run:

```
bundle exec rake "csv_report:unpublishings_by_date_range['2020-10-01 10:00', '2020-12-31 10:00']"
```

## Viewing the Sidekiq UI

We have access to the Sidekiq UI but because Publishing API doesn't have a
frontend we have to use port forwarding to see it in our live environments.

You'll need to have access to our EKS clusters before you can follow these
instructions. There's [documentation here](https://docs.publishing.service.gov.uk/kubernetes/get-started/access-eks-cluster/#access-a-cluster-that-you-have-accessed-before) on how to do that. This means that
you'll need full production access before you can view the Sidekiq UI.

To view the UI run:

```
kubectl -n apps port-forward deployment/publishing-api 8080:8080
```

and then navigate to localhost:8080/sidekiq
