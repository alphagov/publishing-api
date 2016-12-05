# Publishing API

The Publishing API aims to provide _workflow as a service_ so that common
publishing features can be written once and used by all publishing applications
across Government. Content can be stored and retrieved using the API and
workflow actions can be performed, such as creating a new draft or publishing an
existing piece of content.

## Nomenclature

- **Content Item**: A distinct piece of content to be managed by the app. The
majority of things relate to a Content Item
- **Translation**: An object that captures the locale of a piece of content
- **Location**: An object that captures the base_path of a piece of content
and used to denote the location of the content on GOV.UK
- **State**: An object that captures the state of a piece of a content
- **User Facing Version**: An object that captures the version of a piece of
content, which increases over the history of a Content Item
- **Lock Version**: An object that helps to facilitates the prevention of losing
work when multiple users are updating the same content simultaneously
- **Link Set**: A collection of links to other content items. It is used to
capture relationships between pieces of content (e.g. parent/child)
- **User**: A user of the system, which is used to restrict what content is
returned from the API as well as prevent certain actions on content
- **Path Reservation**: An object that attributes a path on GOV.UK to a piece of
content. It is used when paths need to be reserved before that content enters
the system
- **Event Log**: A log of all requests to the Publishing API that have the
potential to mutate its internal state
- **Unpublishing**: An object indicating a previously published content item
which has been removed from the live site.  Can be "gone", "withdrawal", or "redirect".
- **Action**: A record of activity on a particular Content Item, used to assist
custom workflows of publishing applications.

For more information, refer to [doc/api.md](doc/api.md) and
[doc/model.md](doc/model.md).

Generated content items are pushed "downstream" to the content-store, where the frontends
pull the resulting JSON to render a page. [content-store field documentation](https://github.com/alphagov/content-store/blob/master/doc/content_item_fields.md).

## Technical documentation

The Publishing API is a [Ruby on Rails](http://rubyonrails.org/) application
that exposes an internal API to publishing applications. It stores its data in a
[Postgresql](http://www.postgresql.org/) database and sends content downstream
to the draft and live [Content Stores](https://github.com/alphagov/content-store)
as well as on a [Rabbit](https://www.rabbitmq.com/) message queue. Some of the
processing of requests is handled asynchronously through [Sidekiq](http://sidekiq.org/)
which stores jobs in [Redis](http://redis.io/).

Decisions about the design of the Publishing API are recorded as architecture
decision records in the
[doc/arch](https://github.com/alphagov/publishing-api/blob/master/doc/arch)
directory.

### Deleting content items

To delete all traces of a content item you will need to create a migration.

If you need to delete all traces of a content item from the system:

```
require_relative "helpers/delete_content_item"
class RemoveYourContentItem < ActiveRecord::Migration
  # Remove /some/base-path
  def up
    Helpers::DeleteContentItem.destroy_content_items_with_links("some-content-id")
  end
end
```

If you need to delete an instance of a particular content item:

```
require_relative "helpers/delete_content_item"
class RemoveYourContentInstance < ActiveRecord::Migration
  def up
    content_items = ContentItem.where(id: 123)

    Helpers::DeleteContentItem.destroy_supporting_objects(content_items)

    content_items.destroy_all
  end
end
```

If you need to delete just the links for a content item:

```
require_relative "helpers/delete_content_item"
class RemoveLinks < ActiveRecord::Migration
  # Remove /some/base-path
  def up
    Helpers::DeleteContentItem.destroy_links("some-content-id")
  end
end
```

## Dependencies

- [postgres](http://www.postgresql.org/) - the app uses a postgres database
- [redis](http://redis.io/) - the Sidekiq worker stores its jobs in Redis
- [alphagov/content-store](https://github.com/alphagov/content-store) - content is sent to multiple content-stores (draft and live)

These dependencies are set up on the dev vm and if you use bowl to run the app,
it will start both the draft and live content store for you. For more
information about RabbitMQ, see [doc/rabbitmq.md](doc/rabbitmq.md).

## Running the application

`./startup.sh`

It downloads and installs dependencies and starts the app on port 3093.
When using GOV.UK virtual machine the app is available at `publishing-api.dev.gov.uk`.

## Running the test suite

You can run the tests locally with: `bundle exec rake`.

The publishing API includes contract tests which verify that the service
behaves in the way expected by its clients. We use a library called
[`pact`](https://github.com/realestate-com-au/pact) which follows the
*consumer driven contract testing* pattern. What this means is:

- the expected interactions are defined in the [publishing_api_test.rb in gds-api-adapters](https://github.com/alphagov/gds-api-adapters/blob/master/test/publishing_api_test.rb#L19)
- when these tests are run they output a pactfile which is published to [the pact broker](https://pact-broker.dev.publishing.service.gov.uk/)
- the build of publishing api will use this pactfile to test the publishing-api service

The pacts are verified as part of the main test suite run. This verifies
against the pactfiles from both the latest release version, and the master
branch.

You can run the pact verification tests on their own using:

```
$ bundle exec rake pact:verify
```

If you need to run the contract tests against a branch instead of [the
pact-broker](https://pact-broker.dev.publishing.service.gov.uk/), you can run
them against your local gds-api-adapters directory by setting the `USE_LOCAL_PACT`
env variable. This will cause pact to look for the pactfile in
`../gds-api-adapters/spec/pacts/gds_api_adapters-publishing_api.json`. You can
additionally override this location by setting the `GDS_API_PACT_PATH`
variable.

## Example API requests

``` sh
curl https://publishing-api-temp.production.alphagov.co.uk/content<base_path> \
  -X PUT \
  -H 'Content-type: application/json' \
  -d '<content_item_json>'
```

See [doc/api.md](doc/api.md)
and [the pact broker](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest)
for more information.

## Events

Events older then a month are archived to S3, you can import these events back
into your local DB by running the rake tasks in lib/tasks/events.rake, after
you set up the relavent ENV variables. For example if you want to find all the
events that are relavant for a particular content item you can run:
```sh
rake 'events:import_content_item_events[a796ca43-021b-4960-9c99-f41bb8ef2266]'
```
see the rake task for more details.

## Licence

[MIT License](LICENCE)
