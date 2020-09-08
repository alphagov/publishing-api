# RabbitMQ

For information about how we use RabbitMQ, see [here][rabbitmq_doc].

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

## Previewing a message for a document_type

After content is updated, a message is generated and published to the RabbitMQ
exchange. Each message has a shared format, however the contents of the message
is affected by the publishing app and what data it sends over.

As messages for different formats can vary, we have created a rake task to
allow us to easily generate example messages. The example message is generated
from the most recently published message (based off of last public_updated_at)
for the entered document type:

```bash
$ bundle exec rake queue:preview_recent_message[<document_type>]
```

[rabbitmq_doc]: https://docs.publishing.service.gov.uk/manual/rabbitmq.html
