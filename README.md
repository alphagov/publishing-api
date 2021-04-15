# Publishing API

The Publishing API aims to provide _workflow as a service_ so that common
publishing features can be written once and used by all publishing applications
across Government. Content can be stored and retrieved using the API and
workflow actions can be performed, such as creating a new draft or publishing an
existing piece of content.

## Nomenclature

- [**Document**](docs/model.md#document): A document is a piece of content in a
  particular locale. It is associated with editions that represent the versions
  of the document.
- [**Edition**](docs/model.md#edition): The content of a document is represented
  by an edition, it represents a distinct version of a Document.
- [**Content Item**][content-store-field-documentation]: A representation of
  content that can be sent to a [content store][content-store].
- [**Links**](docs/model.md#linking): Used to capture relationships between
  pieces of content (e.g. parent/child). Can be of type
  [link set link][link-set-link] or [edition link][edition-link].
- [**Unpublishing**](docs/model.md#unpublishing): An object indicating a
  previously published edition which has been removed from the live site.
- **User**: A user of the system, which is used to track who initiated requests
  and to restrict access to draft content.
- [**Path Reservation**](docs/model.md#pathreservation): An object that
  attributes a path on GOV.UK to a piece of content. It is used when paths
  need to be reserved before that content enters the system.
- [**Event Log**](docs/model.md#event): A log of all requests to the Publishing
  API that have the potential to mutate its internal state.
- [**Action**](docs/model.md#action): A record of activity on a particular
  edition, used to assist custom workflows of publishing applications.
- [**Link Expansion**](docs/link-expansion.md): A process that converts the
  stored and automatic links for an edition into a JSON representation.
- [**Dependency Resolution**](docs/dependency-resolution.md): A process that
  determines other editions that require updating downstream as a result of a
  change to an edition.

## Technical documentation

The Publishing API is a [Ruby on Rails](http://rubyonrails.org/) application
that exposes an internal API to publishing applications. It stores its data in a
[Postgresql](http://www.postgresql.org/) database and sends content downstream
to the draft and live [Content Stores][content-store] as well as on a
[Rabbit message queue](docs/rabbitmq.md). Some of the processing of
requests is handled asynchronously through [Sidekiq](http://sidekiq.org/)
which stores jobs in [Redis](http://redis.io/).

The endpoints of the Publishing API are documented in [docs/api.md](docs/api.md).

Decisions about the design of the Publishing API are recorded as architecture
decision records in the [docs/arch](docs/arch) directory.

### Deleting Documents, Editions and Links

To delete content from the Publishing API you will need to create a [data
migration][data-migration].

If you need to delete all traces of a document from the system:

```ruby
require_relative "helpers/delete_content"

class RemoveYourDocument < ActiveRecord::Migration
  # Remove /some/base-path
  def up
    Helpers::DeleteContent.destroy_documents_with_links("some-content-id")
  end
end
```

If you need to delete a single edition:

```ruby
require_relative "helpers/delete_content"

class RemoveYourEdition < ActiveRecord::Migration
  def up
    editions = Edition.where(id: 123)

    Helpers::DeleteContent.destroy_supporting_objects(editions)

    editions.destroy_all
  end
end
```

If you need to delete just the links for a document:

```ruby
require_relative "helpers/delete_content"

class RemoveLinks < ActiveRecord::Migration
  # Remove /some/base-path
  def up
    Helpers::DeleteContent.destroy_links("some-content-id")
  end
end
```

## Dependencies

- [postgres](http://www.postgresql.org/) - the app uses a postgres database
- [redis](http://redis.io/) - the Sidekiq worker stores its jobs in Redis
- [alphagov/content-store][content-store] - content is sent to multiple
  content-stores (draft and live)

## Running the test suite

You can run the tests locally with: `bundle exec rake`.

The publishing API includes contract tests which verify that the service
behaves in the way expected by its clients. We use a library called
[`pact`][pact] which follows the *consumer driven contract testing* pattern.
You can run the pact verification tests on their own using:

```sh
$ bundle exec rake pact:verify
```

See [docs/pact_testing.md](docs/pact_testing.md) for more details about the pacts
and the pact broker.

## Example API requests

```sh
curl https://publishing-api.dev.gov.uk/content/<content_id> \
  -X PUT \
  -H 'Content-type: application/json' \
  -d '<content_json>'
```

See [docs/api.md](docs/api.md) and [the pact broker][pact-broker-latest] for more
information.

## Events

Events older then a month are archived to S3, you can import these events back
into your local DB by running the rake tasks in lib/tasks/events.rake, after
you set up the relevant ENV variables. For example if you want to find all the
events that are relevant for a particular content id you can run:

```sh
rake 'events:import_content_id_events[a796ca43-021b-4960-9c99-f41bb8ef2266]'
```

See the rake task for more details.

## Admin tasks

See [admin tasks](docs/admin-tasks.md) for more information

## Contributing

See [the contributing documentation][contributing] for more information.

## Licence

[MIT License](LICENSE)

[content-store]: https://github.com/alphagov/content-store
[content-store-field-documentation]: https://github.com/alphagov/content-store/blob/master/docs/content_item_fields.md
[data-migration]: https://github.com/alphagov/publishing-api/blob/master/CONTRIBUTING.md#are-you-writing-a-migration-to-change-publishing-api-data
[pact]: https://github.com/pact-foundation/pact-ruby
[pact-broker-latest]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest
[link-set-link]: docs/link-expansion.md#patch-link-set---link-set-links
[edition-link]: docs/link-expansion.md#put-content---edition-links
[contributing]: CONTRIBUTING.md
