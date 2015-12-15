# Publishing API syntactic usage

This is the primary interface from publishing apps to the publishing pipeline. Applications PUT items as JSON conforming to a schema specified in govuk-content-schemas.
Content paths are arbitrated internally by the Publishing API, the content is then forwarded to the live and draft content stores, and placed on the message queue for other apps (eg email-alert-service) to consume.

PUT and POST endpoints take an optional integer field `previous_version` in the request, the purpose of this field is to validate that the publishing app sending the request intends to update the latest version of the model in question. Further details of this optimistic locking scenario can be found here.

## `PUT /v2/content/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_from_the_Whitehall_application_to_create_a_content_item_at_/test-item_given_/test-item_has_been_reserved_by_the_Publisher_application)

 - Creates or updates a draft content item with the following steps:
 - Validates that the incoming request is attempting to update the correct internal version of the content item. Responds with 409 when version validation fails.
 - Instantiates a new content item or retrieves an existing item matching the content_id and locale passed in the request.
 - Validates the content item prior to saving. There are multiple validations for draft content items, the main concerns are path integrity, identity uniqueness and version consistency. Validation failures in these cases respond with 422.
 - Increments the version number of the content item.
 - Prepares and sends the draft content item payload downstream to the content store. The payload is modified to include a transmitted_at timestamp to validate message ordering.
 - Sends the draft content item payload to the message queue.

### Required request params:
 - `content_id` the primary identifier for the content being created or updated.
Requests to create a new draft content item:
 - `base_path` must be a valid path
format
 - `publishing_app`
 - `title` required unless format is redirect or gone
 - `public_updated_at` required unless format is redirect or gone
 - `phase` must be one of alpha, beta, live

### Optional request params:
 - `locale` (optional, defaults to en) must be one of I18n.available_locales
Requests to update an existing draft content item:
 - `previous_version` (optional but advised) is used to ensure the request is updating the latest version of this draft. ie. optimistic locking.

## `GET /v2/content/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_return_the_content_item_given_a_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7)

 - Retrieves a draft content item by content_id and optional locale parameter.
 - Exposes the content version in the response.
 - Responds with 404 if no content exists for the given content_id and locale.

### Required request params:
 - `content_id` the primary identifier for the requested content.

### Optional request params:
 - `locale` query parameter for content in a specific locale.

## `POST /v2/content/:content_id/publish`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_publish_request_for_version_3_given_the_content_item_bed722e6-db68-43e5-9079-063f623335a7_is_at_version_3)

 - Validates that update_type is present and optionally that the correct version is being published. Responds with 422 for update_type validation failures and 409 for content version validation failures.
 - Retrieves the draft content item with the matching content_id and locale and creates a live content item based on a subset of the draft attributes.
 - Sends the live content item payload to the content store with a transmission timestamp to validate message ordering.
 - Sends the live content item payload to the message queue.
 - Returns 200 along with the content_id of the newly published item.

### Required request params:
 - `content_id` the primary identifier for the content to publish.
 - `update_type` must be one of major, minor, republish, links

### Optional request params:
 - `locale` (optional) specifies the locale of the content item to be published.
 - `previous_version` (optional but advised) is used to ensure the request is publishing the latest version of this draft. ie. optimistic locking.

## `GET /v2/links/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_get-links_request_given_empty_links_exist_for_content_id_bed722e6-db68-43e5-9079-063f623335a7)

 - Retrieves link sets for the given content_id.
 - Presents the version of the link set in the response.
 - Responds with 404 if no links are available for this content_id.

### Required request params:
 - `content_id` the primary identifier for the content associated with the requested link set.

## `PUT /v2/links/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_update_the_linkset_at_version_3_given_the_linkset_for_bed722e6-db68-43e5-9079-063f623335a7_is_at_version_3)

 - Creates or replaces a link set given a content_id.
 - Validates the presence of the links request parameter and responds with 422 if not present.
 - Validates the link set version in the request and responds with 409 if the lock version is incorrect.
 - Instantiates or retrieves an existing link set.
 - Increments the link set version.
 - Merges the links from the request into an existing link set where applicable.
 - Merges the resulting link set into a draft content payload and sends this to the draft content store.
 - Merges the same link set into a live content payload and sends this to the live content store.
 - Sends the live content payload to the message queue.
 - Returns created or updated link set links in the response.

### Required request parameters:
 - `content_id` the primary identifier for the content associated with the link set to be created or updated.
links a JSON Object containing arrays of links keyed by link type eg.
  ```
    "links": {
      "organisations": [
        "591436ab-c2ae-416f-a3c5-1901d633fbfb"
      ]
    }
  ```

### Optional request params:
 - `previous_version` (optional but advised) is used to ensure the request is updating the latest version of this link set.

## `POST /v2/content/:content_id/discard-draft`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_discard_draft_content_given_a_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7)

 - Deletes the draft content item
 - Creates a new draft from the live item if one exists
 - Validates that the incoming request is attempting to discard the correct internal version of the content item. Responds with 409 when version validation fails
 - Sends the draft content item payload to the content store with a transmission timestamp to validate message ordering
 - By default, the request will discard the draft content item with a locale of 'en'

### Required request parameters:
 - `content_id` the primary identifier for the draft content item to be discarded

### Optional request params:
 - `previous_version` (optional but advised) is used to ensure the request is discarding the latest version of the draft
 - `locale` (optional) is used to discard a specific draft content item where there are multiple translations (defaults to 'en')

## `GET /v2/linked/:content_id`

 [Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_return_the_items_linked_to_it_given_no_content_exists)

  - Retrieves all content items with a link of the specified link_type to the content item with given content_id
  - Returns only the content items' fields that have been requested with the query

### Required request params:
  - `content_id` the primary identifier for the content associated with the requested link set.
  - `link_type` the type of link between the documents
  - `fields[]` an array of fields that are validated against `DraftContentItem` column fields. Any invalid requested field will raise a `400`.
