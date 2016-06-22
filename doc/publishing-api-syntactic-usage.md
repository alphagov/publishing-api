# Publishing API syntactic usage

This is the primary interface from publishing apps to the publishing pipeline. Applications PUT items as JSON conforming to a schema specified in govuk-content-schemas.
Content paths are arbitrated internally by the Publishing API, the content is then forwarded to the live and draft content stores, and placed on the message queue for other apps (eg email-alert-service) to consume.

PUT and POST endpoints take an optional integer field `previous_version` in the request, the purpose of this field is to validate that the publishing app sending the request intends to update the latest lock version of the model in question. Further details of this optimistic locking scenario can be found here.

## `PUT /v2/content/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_from_the_Whitehall_application_to_create_a_content_item_at_/test-item_given_/test-item_has_been_reserved_by_the_Publisher_application)

 - Creates or updates a draft content item with the following steps:
 - Validates that the incoming request is attempting to update the correct internal lock version of the content item. Responds with 409 when lock version validation fails.
 - Instantiates a new content item or retrieves an existing item matching the content_id and locale passed in the request.
 - Validates the content item prior to saving. There are multiple validations for draft content items, the main concerns are path integrity, uniqueness of locale / base_path and lock version consistency. Validation failures in these cases respond with 422.
 - Increments the lock version number of the content item.
 - Prepares and sends the draft content item payload downstream to the draft content store. The payload is modified to include a payload_version to validate message ordering.
 - Sends the draft content item payload to the message queue.

### Required request params:
 - `content_id` the primary identifier for the content being created or updated.
Requests to create a new draft content item:
 - `base_path` must be a valid path format
 - `document_type`
 - `publishing_app`
 - `schema_name`
 - `title` required unless format is redirect or gone
 - `phase` must be one of alpha, beta, live

### Optional request params:
 - `locale` (optional, defaults to en) must be one of I18n.available_locales
Requests to update an existing draft content item:
 - `previous_version` (optional but advised) is used to ensure the request is updating the latest lock version of this draft. ie. optimistic locking.

## `GET /v2/content/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_return_the_content_item_given_a_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7)

 - Retrieves a content item by content_id and optional locale parameter.
 - If the content item exists in both a draft and published state, the draft is returned.
 - Exposes the content lock version in the response.
 - Responds with 404 if no content exists for the given content_id and locale.

### Required request params:
 - `content_id` the primary identifier for the requested content.

### Optional request params:
 - `locale` query parameter for content in a specific locale.

## `POST /v2/content/:content_id/publish`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_publish_request_for_version_3_given_the_content_item_bed722e6-db68-43e5-9079-063f623335a7_is_at_version_3)

 - Validates the previous_version matches that of the content item if one is provided in the payload and raises a 409 otherwise.
 - Validates that update_type is present. If one is not provided, it will try to use the update_type previously set on the content item from the PUT request.
 - Validates that update_type is one of `major`, `minor`, `republish` or `links` and raises a 422 otherwise.
 - Retrieves the draft content item with the matching content_id and locale and changes its state to `published`.
 - Sets the `public_updated_at` on a major update, assuming one hasn't been set through the PUT endpoint.
 - Retains the `public_updated_at` from the previously published item on a minor update, assuming one hasn't been set through the PUT endpoint.
 - Supersedes any previously published content items.
 - Sends the published content item to the live content store.
 - Sends the published content item to the message queue.
 - Returns 200 along with the content_id of the newly published item.

### Required request params:
 - `content_id` the primary identifier for the content to publish.

### Optional request params:
 - `update_type` (optional) must be one of major, minor, republish, links.
 - `locale` (optional) specifies the locale of the content item to be published.
 - `previous_version` (optional but advised) is used to ensure the request is publishing the latest lock version of this draft. ie. optimistic locking.

## `POST /v2/content/:content_id/unpublish`

 [Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#an_unpublish_request_given_a_published_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7)

  - Will refuse to unpublish a lone draft.
  - Will refuse to unpublish a redrafted document unless `discard_drafts` is `true`.
  - Validates that unpublishing `type` is one of `withdrawal`, `gone` or `redirect` and raises a 422 otherwise.
  - Retrieves the live content item with the matching content_id and locale and changes its state to `unpublished`.
  - Creates an `Unpublishing` with the provided details.
  - Will update the `Unpublishing` if the document is already unpublished.
  - Sends the gone/redirect/withdrawal to the live content store.
  - Does not send to the draft content store (unless a draft was discarded).
  - Does not send to the message queue.
  - Returns 200 along with the content_id of the unpublished item.

### Required request params:
  - `content_id` the primary identifier for the content to publish.
  - `type` the type of unpublishing to create/perform.

### Other request params:
  - `explanation` (optional) Message to display on page for `gone`,
                  (required) for `withdrawal`,
                  (ignored) for `redirect`.
  - `alternative_path` (optional) path to turn into a URL to display on page for `gone`,
                       (required) path to redirect to if `redirect`,
                       (ignored) if `withdrawal`.
  - `discard_drafts` (optional) anything other than `true` is considered `false`,
    including being absent.

## `GET /v2/links/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_get-links_request_given_empty_links_exist_for_content_id_bed722e6-db68-43e5-9079-063f623335a7)

 - Retrieves link sets for the given content_id.
 - Presents the lock version of the link set in the response.
 - Responds with 404 if no links are available for this content_id.

### Required request params:
 - `content_id` the primary identifier for the content associated with the requested link set.

## `GET /v2/expanded-links/:content_id`

TODO: Request/Response detail

 - Retrieves expanded link set for the given content_id.
 - Presents the lock version of the link set in the response.
 - Responds with 404 if no links are available for this content_id.

### Required request params:
 - `content_id` the primary identifier for the content associated with the requested link set.

## `PATCH /v2/links/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_update_the_linkset_at_version_3_given_the_linkset_for_bed722e6-db68-43e5-9079-063f623335a7_is_at_version_3)

 - Creates or updates a link set given a content_id.
 - Validates the presence of the links request parameter and responds with 422 if not present.
 - Validates the link set lock version in the request and responds with 409 if the lock version is incorrect.
 - Instantiates or retrieves an existing link set.
 - Increments the link set lock version.
 - Merges the links from the request into an existing link set where applicable.
 - Merges the resulting link set into a draft content payload and sends this to the draft content store.
 - Merges the same link set into a live content payload and sends this to the live content store.
 - Sends the live content payload to the message queue.
 - Returns created or updated link set links in the response.

Note that link sets can be created before or after the PUT requests for the content item.
No downstream requests will be sent if the content item doesn't exist yet.

To delete all the links of a `link_type`, update it with an empty array. This will also remove the reference to the `link_type` from the links. For example:

```
"links": {
  "unwanted_link_type": []
}
```

### Required request parameters:
 - `content_id` the primary identifier for the content associated with the link set to be created or updated.
 - `links` a JSON Object containing arrays of links keyed by link type eg.

```javascript
  "links": {
    "organisations": [
      "591436ab-c2ae-416f-a3c5-1901d633fbfb"
    ]
  }
```

### Optional request params:
 - `previous_version` (optional but advised) is used to ensure the request is updating the latest lock version of this link set.

## `POST /v2/content/:content_id/discard-draft`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_discard_draft_content_given_a_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7)

 - Deletes the draft content item.
 - Re-sends the published content item to the draft content store, if one exists.
 - Validates that the incoming request is attempting to discard the correct internal lock version of the content item. Responds with 409 when lock version validation fails.
 - By default, the request will discard the draft content item with a locale of 'en'.
 - Does not affect the link set for the content item.

### Required request parameters:
 - `content_id` the primary identifier for the draft content item to be discarded

### Optional request params:
 - `previous_version` (optional but advised) is used to ensure the request is discarding the latest lock version of the draft
 - `locale` (optional) is used to discard a specific draft content item where there are multiple translations (defaults to 'en')

## `GET /v2/linked/:content_id`

 [Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_return_the_items_linked_to_it_given_no_content_exists)

  - Retrieves all content items that link to the given content_id for some link_type
  - Returns only the content item's fields that have been requested with the query

### Required request params:
  - `content_id` the primary identifier for the content associated with the requested link set.
  - `link_type` the type of link between the documents
  - `fields[]` an array of fields that are validated against `ContentItem` column fields. Any invalid requested field will raise a `400`.

## `GET /v2/content`

 [Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_get_entries_request_given_a_content_item_exists_in_multiple_locales_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7)

  - Retrieves all content items for a given `document_type` and optional `locale`.
  - Returns only the content item's fields that have been requested with the query.
  - Restricts the content items returned by the `publishing_app` of the current user.
  - Can optionally return content items in all locales by specifying a `locale` of 'all'
  - Can return the `publication_state` of the content item by including it in the `fields[]`
  - Can search for queries against `base_path` or `title`
  - Can order ascending or descending by: content_id, document_type, format, public_updated_at, publishing_app, rendering_app, base_path, locale, updated_at

### Required request params:
  - `document_type` the type of content item to return
  - `locale` (optional) is used to restrict returned content items to a given locale (defaults to 'en')
  - `fields[]` an array of fields that are validated against `ContentItem` column fields. Any invalid requested field will raise a `400`.
  - `q` (optional) the search term to match against `base_path` or `title`
  - `order` (optional) the field to sort results by. Ordered ascending unless prefixed with a hyphen, e.g. `-updated_at`. Defaults to `public_updated_at` descending.

## `GET /v2/linkables`

 [Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_get_linkables_request_given_there_is_content_with_format_'topic')

  - Retrieves specific fields of content items for a given `document_type`.
  - Returns `title`, `content_id`, `publication_state`, `base_path` and `internal_name`.
  - Does not restrict the content items by `publishing_app`
  - Does not paginate the results

### Required request params:
  - `document_type` the type of content item to return

## `POST /lookup-by-base-path`

 [Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_/lookup-by-base-path-request_given_there_are_live_content_items_with_base_paths_/foo_and_/bar)

  - Retrieves published content items for a given collection of base paths.
  - Returns a mapping of `base_path` to `content_id`.

### Required request params:
  - `base_paths` is a collection of base paths to query by (appears in the POST request body)

## `GET /debug/:content_id`

  - Displays debug information for `content_id`

### Required request params:
  - `content_id` the UUID of the content item you wish to debug

### Usage:
  ```
  ssh backend-1.integration -CNL 8888:127.0.0.1:3093
  ```

  And then open http://localhost:8888/debug/f141fa95-0d79-4aed-8429-ed223a8f106a
  Alternativly this to your hosts file and open

  ```
  127.0.0.1 publishing-api.integration.publishing.service.gov.uk
  ```

  http://publishing-api.integration.publishing.service.gov.uk:8888/debug/f141fa95-0d79-4aed-8429-ed223a8f106a
