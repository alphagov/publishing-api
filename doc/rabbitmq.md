# RabbitMQ

Publishing API relies on RabbitMQ as its messaging bus. If you are using the
development VM, it will be installed for you and the required users and topic
exchanges will be set up. If not, you need to install RabbitMQ and add them
yourself. Once RabbitMQ is installed, visit `http://localhost:15672` and:

1. add a `publishing_api` user (under "Admin") with the password `publishing_api`
2. add a `published_documents` and a `published_documents_test` topic exchange
   (under "Exchanges")
3. give the `publishing_api` user permissions for the new exchanges.

A more detailed specification of how to configure RabbitMQ can be found in the
[puppet manifest][puppet_manifest] for the Publishing API.

Publishing to the message queue can be disabled by setting the
`DISABLE_QUEUE_PUBLISHER` environment variable.

## Post-publishing notifications

After an edition is changed, a message is published to RabbitMQ. It will be
published to the `published_documents` topic exchange with the routing_key
`"#{edition.schema_name}.#{event_type}"`. Interested parties can subscribe to
this exchange to perform post-publishing actions. For example, a search
indexing service would be able to add/update the search index based on these
messages. Or an email notification service would be able to send email updates
(see https://github.com/alphagov/email-alert-service).

### `event_type`

- `major`: Used when an edition is published with an `update_type` of major.
- `minor`: Used when an edition is published with an `update_type` of minor.
- `republish`: Used when an edition is published with an `update_type` of republish.
- `links`: Used whenever links related to an edition have changed.
- `unpublish`: Used when an edition is unpublished.

[puppet_manifest]: https://github.com/alphagov/govuk-puppet/blob/master/modules/govuk/manifests/apps/publishing_api/rabbitmq.pp
