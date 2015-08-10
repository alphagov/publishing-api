# Publishing API

This is a Rails application that proxies requests to multiple content-stores. Our
use case for this is to keep two copies of the frontend of GOV.UK running: one
which the public sees and another which is only used by people working on
content to review work in progress.

Publishing apps will talk to the publishing-api rather than the content-store.
Normal publishing requests are forwarded to both the live and draft
content-stores, whereas draft documents would only be forwarded to the draft
content-store.

### Dependencies

- [alphagov/url-arbiter](https://github.com/alphagov/url-arbiter) - publishing-api will take over content-store's job of updating url-arbiter. This is to prevent race conditions as two content-stores try to register with the same url-arbiter.
- [alphagov/content-store](https://github.com/alphagov/content-store) - publishing-api's function is to proxy requests to multiple content-stores (eg a draft and a live content-store)

Publishing API relies on RabbitMQ as its messaging bus. If you are using the
development VM, it will be installed for you and the required users and topic
exchanges will be set up. If not, you need to install RabbitMQ and add them
yourself. Once RabbitMQ is installed, visit http://localhost:15672 and:

1. add a `publishing_api` user (under "Admin") with the password `publishing_api`
2. add a `published_documents` and a `published_documents_test` topic exchange
   (under "Exchanges")
3. give the `publishing_api` user permissions for the new exchanges.

A more detailed specification of how to configure RabbitMQ can be found in the
[puppet manifest](https://github.gds/gds/puppet/blob/master/modules/govuk/manifests/apps/publishing_api/rabbitmq.pp)
for the publishing API.

Publishing to the message queue can be disabled by setting the
`DISABLE_QUEUE_PUBLISHER` environment variable.

## Post-publishing notifications

After a content item is added or updated, a message is published to RabbitMQ.
It will be published to the `published_documents` topic exchange with the
routing_key `"#{content_item.format}.#{content_item.update_type}"`. Interested parties can
subscribe to this exchange to perform post-publishing actions. For example, a
search indexing service would be able to add/update the search index based on
these messages. Or an email notification service would be able to send email
updates (see https://github.com/alphagov/email-alert-service).

### Running the application

`./startup.sh`

Dependencies will be dowloaded and installed and the app should start up on
port 3093. Currently on GOV.UK machines it also be available at
`publishing-api-temp.dev.gov.uk`, but this will change to
`publishing-api.dev.gov.uk` in the near future.

## Running the test suite

You can run the tests locally with: `rake`.

### Example API requests

``` sh
curl https://publishing-api-temp.production.alphagov.co.uk/content<base_path> -X PUT \
    -H 'Content-type: application/json' \
    -d '<content_item_json>'
```

See the documentation for [content-store](https://github.com/alphagov/content-store) for full details.

## Licence

[MIT License](LICENCE)
