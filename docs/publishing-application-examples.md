# Publishing application examples

This documentation aims to explain integration steps for a publishing
application to manage content and links within the Publishing API.
Included are request flow concepts and trivial code examples to aid the
developer with integration steps.

The Publishing API provides a set of endpoints aimed at providing client
publishing applications a way to draft and modify content and links, and
then to publish or unpublish them.

Content and links for a shared content item can be modified separately on
different endpoints, these distinct changes will ultimately modify the
downstream representation in the content store.

## Authentication and audit trail

Publishing applications may need to track the changes made to a content item
against an authenticated user. In order to do this
[integration with GDS-SSO is required][gds-sso-integration], this usually
means implementing a persisted user model in the publishing application and
applying a filter in the application controller to authenticate the user.
The `User#uid` value can then be sent as a request parameter when drafting
content to restrict access. eg.

```
  access_limited : ["8f3173bb-ee2a-48a2-aa86-f2f030830888"]
```

## Draft and Publish endpoint flow

The Publishing API prescribes a draft-to-live workflow where the publishing
application submits new draft content, this content may then be updated via the
same endpoint and finally can be published in a discrete endpoint request.

```
  Publishing Application                                 Publishing API

  [ Initial draft ] -----------------------------------> [ PUT /v2/content/:content_id ]
                                                                            |
               Responds with updated content including lock version         |
           <----------------------------------------------------------------


  [ Updated draft ] -----------------------------------> [ PUT /v2/content/:content_id ]
          |
          |            Publish request
           --------------------------------------------> [ POST /v2/content/:content_id/publish ]
```

## Configuring the Publishing API for use in a publishing application

HTTP requests to Publishing API endpoints should be made using the
[publishing-api v2 gds-api-adapters client library][publishing-api-gds-api-adapters].
A trivial example of how to configure a publishing application to use the
Publishing API v2 client adapter would be:

```ruby
  require "gds_api/publishing_api_v2"

  publishing_api = GdsApi::PublishingApiV2.new(Plek.find("publishing-api"))

```

### Configuring authentication

Individual applications require bearer tokens to access the publishing API. To
create and configure tokens:

0. Go to the API users config in Signon for each environment (e.g.
  https://signon.integration.publishing.service.gov.uk/api_users). You must be
  a superadmin to see this page.
0. Find your application in the list or create a new API user for it. The app's
  email address should be `name-of-app@digital.cabinet-office.gov.uk`.
0. Add a publishing API application token for that user.
0. Add the tokens for each environment to [govuk-secrets][govuk-secrets]
  ([example][govuk-secrets-token-example]).
0. Configure [govuk-puppet][govuk-puppet] to create an environment variable for
  the token ([example][govuk-puppet-token-example]).
0. Use the environment variable in the app:

```ruby
@publishing_api = GdsApi::PublishingApiV2.new(
  Plek.find("publishing-api"),
  bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] || "example",
)
```

## Drafting content from a publishing app

Publishing applications should use the `PUT /v2/content/:content_id` endpoint
to add content.
Please refer to the [api documentation](api.md) and
[model documentation](model.md) for further details.

The publishing application is responsible for the generation of a content_id,
the primary identifier for content in the Publishing API and content store.
The convention is to use `SecureRandom.uuid` to generate a valid content_id.

Details of how the payload should be constructed including required fields can
be found in [govuk-content-schemas][govuk-content-schemas] where each format is
defined for both publishing and frontend applications. For example the payload
for a [case study][case-study-schema] would need to provide `body` and
`first_public_at` attributes along with other mandatory attributes such as
`title` and `base_path`.

Using the Publishing API v2 client adapter with a valid content_id and payload,
the following example would make the request.

```ruby
  publishing_api = GdsApi::PublishingApiV2.new(Plek.find("publishing-api"))
  content_id = SecureRandom.uuid
  guide = GuideContentModel.new(
    content_id: content_id,
    base_path: "/vat-rates",
    title: "VAT rates",
    description: "VAT rates for goods and services",
    details: { body: "Something about VAT" },
    access_limited : ["8f3173bb-ee2a-48a2-aa86-f2f030830888"],
    rendering_app: "frontend",
    publishing_app: "my-shiny-publishing-app",
    public_updated_at: "2014-05-14T13:00:06.000Z",
    document_type: "guide",
    schema_name: "guide",
    routes: [{
      path: "/vat-rates", type: "exact"
    }]
  )
  payload = guide.as_json
  publishing_api.put_content(content_id, payload)
```


The response body would contain a presentation of the saved edition
including the item lock version eg.

```js
  {"content_id":"940b88db-8f15-4859-b5b2-4761ba62a067",
  "locale":"en",
  "base_path":"/vat-rates",
  "title":"VAT rates",
  "description":"VAT rates for goods and services",
  "document_type":"guide",
  "schema_name":"guide",
  "public_updated_at":"2014-05-14T13:00:06.000Z",
  "details":{"body":"Something about VAT"},
  "access_limited":["8f3173bb-ee2a-48a2-aa86-f2f030830888"],
  "routes":[{"path":"/vat-rates","type":"exact"}],
  "redirects":[],
  "publishing_app":"my-shiny-publishing-app",
  "rendering_app":"frontend",
  "lock version":"1"}
```

Which could then be used to update the local model instance in the publishing
application:

```ruby
  parsed_response = JSON.parse(response.body)
  guide.update_attributes(parsed_response)
```

## Error handling

The response will indicate any errors that may have occurred in making the
request. These may be validation errors for required content fields or more
general errors pertaining to lock version locking. A 4xx error code will be
returned along with error messages in the `response.body.error` object. eg.

```js
  {
    "status": 409,
    "headers": {
      "Content-Type": "application/json; charset=utf-8"
    },
    "body": {
      "error": {
        "code": 409,
        "message": "Conflict",
        "fields": {
          "previous_version": [
            "does not match"
          ]
        }
      }
    }
  }
```

## LockVersioning

The response body contains the current lock version of the document for GET
and PUT `/v2/content/:content_id` endpoints. This allows the publishing
application to track the updated draft lock version, this is can in turn be
used in an optional previous_version request parameter to prevent conflicting
updates from overwriting content. ie.


```
  Publishing Application                                 Publishing API

  [ Initial draft ] -----------------------------------> [ PUT /v2/content/:content_id ]
                                                                       |
                    Responds with lock version 1                       |
                    <--------------------------------------------------

  [ Update lock version 1 ] ------ previous_version: 1 -----> [ PUT /v2/content/:content_id ]
                                                                       |
                    Responds with lock version 2                       |
                    <--------------------------------------------------

                    This next request to update will fail since lock version increment.

  [ Update lock version 1 ] ------ previous_version: 1 -----> [ PUT /v2/content/:content_id ]

                    This next request to update will succeed.

  [ Update lock version 2 ] ------ previous_version: 2 -----> [ PUT /v2/content/:content_id ]
```



[GET endpoints also exist for content and links](api.md) should the publishing
application wish to make a request for the current state of these items in the
Publishing API.


## Publishing

Publishing content is handled by a discrete endpoint accepting the
`content_id` of the item to publish and optionally the `locale` of the item to
publish. eg.

```
POST /v2/940b88db-8f15-4859-b5b2-4761ba62a067/publish?locale=fr
```

When making a request to publish, the current draft item of the same content_id
and locale is used as the basis of the payload sent downstream to the live
content store.

## Automatic Redirects

Publishing API automatically creates redirects for documents when
their base paths change between editions.
When the edition is created as a draft, a redirect edition is also created in
draft. When the edition is published, the redirect is also published.

---

Is there anything wrong with the documentation? If so:

- Open a pull request
- Speak to the Publishing Platform team

[gds-sso-integration]: https://github.com/alphagov/gds-sso#integration-with-a-rails-3-app
[publishing-api-gds-api-adapters]: https://github.com/alphagov/gds-api-adapters/blob/master/lib/gds_api/publishing_api_v2.rb
[case-study-schema]: https://github.com/alphagov/govuk-content-schemas/blob/master/dist/formats/case_study/publisher_v2/schema.json
[govuk-content-schemas]: https://github.com/alphagov/govuk-content-schemas
[govuk-puppet]: https://github.com/alphagov/govuk-puppet
[govuk-puppet-token-example]: https://github.com/alphagov/govuk-puppet/pull/6978
[govuk-secrets]: https://github.com/alphagov/govuk-secrets
[govuk-secrets-token-example]: https://github.com/alphagov/govuk-secrets/pull/130
