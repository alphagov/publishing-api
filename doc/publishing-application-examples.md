# Publishing application examples

This documentation aims to explain integration steps for a publishing application to manage content items and links within the Publishing API. Included are request flow concepts and trivial code examples to aid the developer with integration steps.

The publishing API provides a set of endpoints aimed at providing client publishing applications a way to draft and modify content and links and publish them.
Content and links for a shared content item can be modified separately on different endpoints, these distinct changes will ultimately modify the downstream content item in the content store.

## Authentication and audit trail

Publishing applications may need to track the changes made to a content item against an authenticated user. In order to do this [integration with GDS-SSO is required](https://github.com/alphagov/gds-sso#integration-with-a-rails-3-app), this usually means implementing a persisted user model in the publishing application and applying a filter in the application controller to authenticate the user.
The `User#uid` value can then be sent as a request parameter when drafting content to restrict access. eg.

```
  access_limited : ["8f3173bb-ee2a-48a2-aa86-f2f030830888"]
```

## Draft and Publish endpoint flow

The Publishing API prescribes a draft-to-live workflow where the publishing application submits new draft content, this content may then be updated via the same endpoint and finally the content item can be published in a discreet endpoint request.

```
  Publishing Application                                 Publishing API

  [ Initial draft ] -----------------------------------> [ PUT /v2/content/:content_id ]
                                                                       |
               Responds with updated content item including version    |
           <-----------------------------------------------------------


  [ Updated draft ] -----------------------------------> [ PUT /v2/content/:content_id ]
          |
          |            Publish request
           --------------------------------------------> [ POST /v2/content/:content_id/publish ]
```

## Configuring the Publishing API for use in a publishing application

HTTP requests to Publishing API endpoints should be made using the [publishing-api v2 gds-api-adapters client library](https://github.com/alphagov/gds-api-adapters/blob/master/lib/gds_api/publishing_api_v2.rb).
A trivial example of how to configure a publishing application to use the publishing API v2 client adapter would be

```
  require "gds_api/publishing_api_v2"

  publishing_api = GdsApi::PublishingApiV2.new(Plek.new("publishing-api"))

```

## Drafting a content item from a publishing app

Publishing applications should use the `PUT /v2/content/:content_id` endpoint to add content.
Please refer to the [syntactic documentation](https://gov-uk.atlassian.net/wiki/display/TECH/Publishing+Platform) and [semantic documentation](./semantics-of-the-publishing-api.md) for further details.

The publishing application is responsible for the generation of a content_id, the primary identifier for content in the publishing API and content store. The convention is to use SecureRandom.uuid to generate a valid content_id.

Details of how the payload should be constructed including required fields can be found in [govuk-content-schemas](https://github.com/alphagov/govuk-content-schemas) where each format is defined for both publishing and frontend applications. For example the payload for a case study would need to provide `body` and `first_public_at` attributes along with other mandatory attributes such as `content_id` and `base_path`.

Using the publishing API v2 client adapter with a valid content_id and payload, the following example would make the request.

```
  publishing_api = GdsApi::PublishingApiV2.new(Plek.new("publishing-api"))
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
    format: "guide",
    routes: [{
      path: "/vat-rates", type: "exact"
    }]
  )
  payload = guide.as_json
  publishing_api.put_content(content_id, payload)
```


The response body would contain a presentation of the saved content item including the item version eg.

```
  {"id":1,
  "content_id":"940b88db-8f15-4859-b5b2-4761ba62a067",
  "locale":"en",
  "base_path":"/vat-rates",
  "title":"VAT rates",
  "description":"VAT rates for goods and services",
  "format":"guide",
  "public_updated_at":"2014-05-14T13:00:06.000Z",
  "details":{"body":"Something about VAT"},
  "access_limited":["8f3173bb-ee2a-48a2-aa86-f2f030830888"],
  "routes":[{"path":"/vat-rates","type":"exact"}],
  "redirects":[],
  "publishing_app":"my-shiny-publishing-app",
  "rendering_app":"frontend",
  "version":"1"}
```

which could then be used to update the model instance:

```
  parsed_response = JSON.parse(response.body)
  guide.update_attributes(parsed_response)
```

## Error handling

The response will indicate any errors that may have occurred in making the request. These may be validation errors for required content fields or more general errors pertaining to version locking. A 4xx error code will be returned along with error messages in the `response.body.error` object. eg.

```
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

## Versioning

The response body contains the current version of the content item for GET and PUT `/v2/content/:content_id` endpoints. This allows the publishing application to track the updated draft version, this is can in turn be used in an optional previous_version request parameter to prevent conflicting updates from overwriting content. ie.


```
  Publishing Application                                 Publishing API

  [ Initial draft ] -----------------------------------> [ PUT /v2/content/:content_id ]
                                                                       |
                    Responds with version 1                            |
                    <--------------------------------------------------

  [ Update version 1 ] ------ previous_version: 1 -----> [ PUT /v2/content/:content_id ]
                                                                       |
                    Responds with version 2                            |
                    <--------------------------------------------------

                    This next request to update will fail since version increment.

  [ Update version 1 ] ------ previous_version: 1 -----> [ PUT /v2/content/:content_id ]

                    This next request to update will succeed.

  [ Update version 2 ] ------ previous_version: 2 -----> [ PUT /v2/content/:content_id ]
```



[GET endpoints also exist for content and links](https://gov-uk.atlassian.net/wiki/display/TECH/Publishing+Platform) should the publishing application wish to make a request for the current state of these items in the Publishing API.


## Publishing

Publishing a content item is handled by a discrete endpoint accepting the `content_id` of the item to publish and optionally the `locale` of the item to publish. eg.

```
POST /v2/940b88db-8f15-4859-b5b2-4761ba62a067/publish?locale=fr
```

When making a request to publish, the current draft item of the same content_id and locale is used as the basis of the payload send downstream to the live content store.

It’s worth noting that the internal versioning of the Publishing API only tracks the version of draft updates, this means that publishing apps are responsible for maintaining versioning of published content, for example the Publishing API may contain draft versions 1 to 10 of a content item.
This item may have been published at version 5 and 10, the publishing application may wish to represent this as version 1 and version 2 as these are the significant publishings of the content:

```
  Publishing Application                                 Publishing API

  [ Initial draft ] -----------------------------------> [ Draft version 1 ]

  [ Updated draft ] -----------------------------------> [ Draft version 2 ]
          |
          |            Publish request
           --------------------------------------------> [ Draft version 2 ] --> [ Published version 2 ]
                                                                                            |
  [ Published version 1 ] <-----------------------------------------------------------------

```


---

Is there anything wrong with the documentation? If so:

- Open a pull request
- Speak to the Publishing Platform team
