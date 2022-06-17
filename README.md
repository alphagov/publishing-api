# Publishing API

The Publishing API aims to provide _workflow as a service_ so that common publishing features can be written once and used by all publishing applications across Government. Content can be stored and retrieved using the API and workflow actions can be performed, such as creating a new draft or publishing an existing piece of content.

Publishing API sends content downstream to the draft and live [Content Stores][content-store], as well as on a [Rabbit message queue](docs/rabbitmq.md), which enables things like sending emails to users subscribed to that content. Read "[Downstream Sidekiq background processing triggered by publishing](https://docs.publishing.service.gov.uk/manual/architecture-deep-dive.html#downstream-sidekiq-background-processing-triggered-by-publishing)".

## Nomenclature

- [**Document**](docs/model.md#document): A document is a piece of content in a particular locale. It is associated with editions that represent the versions of the document.
- [**Edition**](docs/model.md#edition): The content of a document is represented by an edition, it represents a distinct version of a Document.
- [**Content Item**][content-store-field-documentation]: A representation of content that can be sent to a [content store][content-store].
- [**Links**](docs/model.md#linking): Used to capture relationships between pieces of content (e.g. parent/child). Can be of type [link set link][link-set-link] or [edition link][edition-link].
- [**Unpublishing**](docs/model.md#unpublishing): An object indicating a previously published edition which has been removed from the live site.
- **User**: A user of the system, which is used to track who initiated requests and to restrict access to draft content.
- [**Path Reservation**](docs/model.md#pathreservation): An object that attributes a path on GOV.UK to a piece of content. It is used when paths need to be reserved before that content enters the system.
- [**Event Log**](docs/model.md#event): A log of all requests to the Publishing API that have the potential to mutate its internal state.
- [**Action**](docs/model.md#action): A record of activity on a particular edition, used to assist custom workflows of publishing applications.
- [**Link Expansion**](docs/link-expansion.md): A process that converts the stored and automatic links for an edition into a JSON representation.
- [**Dependency Resolution**](docs/dependency-resolution.md): A process that determines other editions that require updating downstream as a result of a change to an edition.

## Technical documentation

This is a Ruby on Rails app, and should follow [our Rails app conventions](https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html).

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies. Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.


**Use GOV.UK Docker to run any commands that follow.**

## Running the test suite

You can run the tests locally with: `bundle exec rake`.

The Publishing API also has [contract tests with GDS API Adapters](https://docs.publishing.service.gov.uk/manual/pact-testing.html) (where it acts as the "provider") and [with Content Store](https://docs.publishing.service.gov.uk/manual/pact-testing.html#special-cases-and-tech-debt) ( where it acts as the contract "consumer"). [Read the guidance for how to run the tests locally](https://docs.publishing.service.gov.uk/manual/pact-testing.html#running-pact-tests-locally).

### Further documentation

- [Publishing API's API](docs/api.md)
- [Architecture decision records](docs/arch)
- [Admin tasks](docs/admin-tasks.md)
- [Deleting Documents, Editions and Links](docs/deleting-content.md)
- [Writing data migrations](docs/data-migration.md)

## Licence

[MIT License](LICENSE)

[content-store]: https://github.com/alphagov/content-store
[content-store-field-documentation]: https://github.com/alphagov/content-store/blob/master/docs/content_item_fields.md
[link-set-link]: docs/link-expansion.md#patch-link-set---link-set-links
[edition-link]: docs/link-expansion.md#put-content---edition-links
[contributing]: CONTRIBUTING.md
