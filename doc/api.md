# Publishing API's API

This is the primary interface from publishing apps to the publishing pipeline. Applications PUT items as JSON conforming to a schema specified in govuk-content-schemas.
Content paths are arbitrated internally by the Publishing API, the content is then forwarded to the live and draft content stores, and placed on the message queue for other apps (eg email-alert-service) to consume.

## Index
- [`PUT /v2/content/:content_id`](#put-v2contentcontent_id)
- [`POST /v2/content/:content_id/publish`](#post-v2contentcontent_idpublish)
- [`POST /v2/content/:content_id/unpublish`](#post-v2contentcontent_idunpublish)
- [`POST /v2/content/:content_id/discard-draft`](#post-v2contentcontent_iddiscard-draft)
- [`GET /v2/content`](#get-v2content)
- [`GET /v2/content/:content_id`](#get-v2contentcontent_id)
- [`PATCH /v2/links/:content_id`](#patch-v2linkscontent_id)
- [`GET /v2/links/:content_id`](#get-v2linkscontent_id)
- [`GET /v2/expanded-links/:content_id`](#get-v2expanded-linkscontent_id)
- [`GET /v2/linked/:content_id`](#get-v2linkedcontent_id)
- [`GET /v2/linkables`](#get-v2linkables)
- [`POST /lookup-by-base-path`](#post-lookup-by-base-path)
- [`GET /debug/:content_id`](#get-debugcontent_id)

### Optimistic locking (`previous_version`)

All PUT and POST endpoints take an optional integer field `previous_version` in
the request. This allows the Publishing API to check that the publishing app
sending the request intends to update the latest lock version of the model in
question.

If `previous_version` is provided, the Publishing API will confirm that the
provided value matches that of the content item in the Publishing API. If it
does not, a [409](#409-conflict) response will be given.

### Status Codes

#### `409` ([Conflict](https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.10))

See [Optimistic locking](#optimistic-locking).

#### `422` ([Unprocessable Entity](https://tools.ietf.org/html/rfc4918#section-11.2))

Used for validation failures.

## `PUT /v2/content/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_from_the_Whitehall_application_to_create_a_content_item_at_/test-item_given_/test-item_has_been_reserved_by_the_Publisher_application)

Used to create or update draft content items.

Unless explicitly stated, each request parameter is used to set the respective
field on the content item model.

 - Prepares and sends the draft content item payload downstream to the draft content store. The payload is modified to include a payload_version to validate message ordering.
 - Sends the draft content item payload to the message queue.

### Required request params:
 - [`content_id`](model.md#content_id)
   - Specifies either which content item to update, or the `content_id` for the
     new content item.
 - [`base_path`](model.md#base_path)
 - [`redirects`](model.md#redirects)
   - Only required when the `document_type` is "redirect".
 - [`publishing_app`](model.md#publishing_app)
 - [`details`](model.md#details)
   - Not required when the respective `document_type` does not require any `details`.
 - [`routes`](model.md#routes)
   - Not required, and must not be present (TODO: Check this) when the
     `document_type` is "redirect".

### Required for renderable document types
All document types are considered renderable, except "redirect" and "gone".
 - [`title`](model.md#title)
 - [`public_updated_at`](model.md#public_updated_at)
   - (TODO: Check if this is really not required).
 - [`rendering_app`](model.md#rendering_app)
 - [`title`](model.md#title)

### Optional request params:
 - [`locale`](model.md#locale) (default: "en")
   - If included, this will either used to find the existing content item, or
     set on the new content item.
   - Must be one of I18n.available_locales
 - [`phase`](model.md#phase) (default: "live")
   - Must be one of "alpha", "beta", "live".
 - [`document_type`](model.md#document_type)
   - If `document_type` is not specified, the value from `format` (if given)
     will be used instead.
 - [`schema_name`](model.md#schema_name)
   - If `schema_name` is not specified, the value from `format` (if given)
     will be used instead.
 - [`format`](model.md#format)
   - *Deprecated*, `document_type` and `schema_name` should be specified instead.
 - [`update_type`](model.md#update_type)
 - [`access_limited`](model.md#access_limited)
 - [`analytics_identifier`](model.md#analytics_identifier)
 - [`description`](model.md#description)
 - [`last_edited_at`](model.md#last_edited_at)
   - If `last_edited_at` is not specified, and the `update_type` specified in the request is
     "major" or "minor", then `last_edited_at` will be set to the current time.
     - (TODO: What should happen if the update_type is changed in a new request?)
 - [`links`](model.md#links)
 - [`need_ids`](model.md#need_ids)
 - `previous_version`
   - This field is a special case, as its not present on the content item
     model. Its used is described in [Optimistic locking](#optimistic-locking).

## `POST /v2/content/:content_id/publish`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_publish_request_for_version_3_given_the_content_item_bed722e6-db68-43e5-9079-063f623335a7_is_at_version_3)

Transitions a content item from a draft state to a published state. The content item will be sent to the live content store.

### Path Parameters
- [`content_id`](model.md#content_id)
  - Identifies the draft content item to publish

### JSON Attributes
- [`update_type`](model.md#update_type) (conditionally required)
  - Accepts: "major", "minor", "republish", "links"
  - Will fallback to the `update_type` set during drafting, will return a 422 if not provided with either.
- [`locale`](model.md#locale) (optional, default: "en")
  - Accepts: An available locale from the [Rails I18n gem](https://github.com/svenfuchs/rails-i18n)
  - Specifies which translation of the content item to publish
- [`previous_version`](model.md#lock_version) (optional)
  - Used to ensure that the version being published is the same as the draft created (to avoid publishing a different users later edits)

### State Changes
- The draft content item with the matching `content_id`, `locale` and `previous_version` will have it's state transition to "published"
- Any previously published content items for this `content_id` and `locale` will have their state transitioned to "superseded"
- For an `update_type` of "major" the `public_updated_at` field will be updated to the current timestamp
- If the content item has a non blank `base_path`:
  - If the `base_path` of the draft item differs to the published version of this content item:
    - Redirects to this content item will be published
  - Any published content items that have a matching `base_path` and `locale` and have a document_type of "coming soon", "gone", "redirect" or "unpublishing" will have their state changed to "unpublished" with a type of "substitute"
  - The live content store will be updated with the content item
  - All published content items that link to this item (directly or through a recursive chain of links) will be updated in the live content store.

## `POST /v2/content/:content_id/unpublish`

 [Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#an_unpublish_request_given_a_published_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7)

Transitions a content item into an unpublished state. The content item will be updated or removed from the live content store depending on the unpublishing type.

### Path Parameters
- [`content_id`](model.md#content_id)
  - Identifies the content item to unpublish.

### JSON Attributes
- `allow_draft` (optional)
  - Boolean value, cannot be `true` if `discard_drafts` is also true.
  - Specifies that if a draft content item is present it will be transitioned to "unpublished" rather than the published version of this content item, which itself will transition to "superseded".
- `alternative_path` (conditionally required)
  - Required for a `type` of "redirect", Optional for a `type` of "gone".
  - If specified, this should be [`base_path`](model.md#base_path).
- `discard_drafts` (optional)
  - Boolean value, cannot be `true` if `allow_drafts` is also true
  - Specifies that the published version of this content_item  will be transitioned to "unpublished" and a draft version of it will be removed from the database and draft content store
- `explanation` (conditionally required)
  - Required for a `type` of "withdrawal", Optional for a type of "gone".
  - Message that will be displayed on the page that has been unpublished.
- [`locale`](model.md#locale) (optional, default: "en")
  - Accepts: An available locale from the [Rails I18n gem](https://github.com/svenfuchs/rails-i18n)
  - Specifies which translation of the content item to unpublish
- [`previous_version`](model.md#lock_version) (optional)
  - Used to ensure that the version being unpublished is the most recent version of the content item.
- `type` (required)
  - Accepts: "gone", "redirect", "withdrawal", "vanish"
  - The type of unpublishing that is being performed.

### State Changes
- If the unpublishing `type` is "gone", "redirect" or "withdrawal":
  - If the content item matching `content_id`, `locale` and `previous_version` has a draft and `allow_draft` is `true`:
    - The draft content item transitions state to "unpublished".
    - If a previously published versions of the content_item exists it's state will transition to "superseded".
  - If the content item matching `content_id`, `locale` and `previous_version` has a draft and `discard_drafts` is `true`:
    - The draft content item will be deleted from the Publishing API.
    - The draft content item will be removed from the draft content store.
    - The published content item transitions state to "unpublished".
  - If the content item matching `content_id`, `locale` and `previous_version` has no draft:
    - The published content item transitions state to "unpublished".
  - The live content store will be updated with the unpublished content item.
  - All published content items that link to this item (directly or through a recursive chain of links) will be updated in the live content store.
- If the unpublishing `type` is "vanish":
  - The content item will be removed from the live content store.

## `POST /v2/content/:content_id/discard-draft`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_discard_draft_content_given_a_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7)

Deletes a draft version of a content item. Replaces the draft content item on the draft content store with the published item, if one exists.

### Path Parameters
- [`content_id`](model.md#content_id)
  - Identifies the content item whose draft will be deleted.

### JSON Attributes
- [`locale`](model.md#locale) (optional, default: "en")
  - Accepts: An available locale from the [Rails I18n gem](https://github.com/svenfuchs/rails-i18n)
  - Specifies which translation of the draft content item to delete
- [`previous_version`](model.md#lock_version) (optional)
  - Used to ensure the version being discarded is the current draft.

### State Changes
- The draft content item will be deleted from the Publishing API.
- The draft content item will be removed from the draft content store.
- If a published content item exists it will be added to the draft content store.

## `GET /v2/content`

 [Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_get_entries_request_given_a_content_item_exists_in_multiple_locales_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7)

Retrieves a paginated list of content items for the provided query string parameters. If content items exists in both a published and a draft state, the draft is returned.

### Query String Parameters
- [`document_type`](model.md#document_type) (required)
  - The type of content item to return
- `fields[]` (optional)
  - Accepts an array of: "analytics_identifier", "api_url", "base_path", "content_id", "description", "document_type", "locale", "public_updated_at", "schema_name", "title", "web_urls"
  - Determines which fields will be returned in the response, if omitted all fields will be returned.
- [`locale`](model.md#locale) (optional, default "en")
  - Accepts: An available locale from the [Rails I18n gem](https://github.com/svenfuchs/rails-i18n)
  - Used to restrict content items to a given locale
- `order` (optional, default: "-public_updated_at")
  - The field to sort the results by.
  - Returned in an ascending order unless prefixed with a hyphen, e.g. "-base_path".
- `page` (optional, default: 1)
  - The page of results requested.
- `per_page` (optional, default: 50)
  - The number of results to be shown on a given page.
- `q` (optional)
  - Search term to match against [`title`](model.md#title) and [`base_path`](model.md#base_path) fields.

## `GET /v2/content/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_return_the_content_item_given_a_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7)

Retrieves a single content item for a content_id and locale. By default the most recent version is returned, which may be a draft.

### Path Parameters
- [`content_id`](model.md#content_id)
  - Identifies the content item to be returned.

### Query String Parameters
- [`locale`](model.md#locale) (optional, default "en")
  - Accepts: An available locale from the [Rails I18n gem](https://github.com/svenfuchs/rails-i18n)
  - Used to return a specific translation.
- [`version`](model.md#user_facing_version) (optional)
  - Specify a particular user facing version of this content item.
  - If omitted the most recent version is returned.

## `PATCH /v2/links/:content_id`

[Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_update_the_linkset_at_version_3_given_the_linkset_for_bed722e6-db68-43e5-9079-063f623335a7_is_at_version_3)

 - Creates or updates a link set given a content_id.
 - Validates the presence of the links request parameter and responds with (422)[#status-422] if not present.
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
 - `previous_version`

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

## `GET /v2/linked/:content_id`

 [Request/Response detail](https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_return_the_items_linked_to_it_given_no_content_exists)

  - Retrieves all content items that link to the given content_id for some link_type
  - Returns only the content item's fields that have been requested with the query

### Required request params:
  - `content_id` the primary identifier for the content associated with the requested link set.
  - `link_type` the type of link between the documents
  - `fields[]` an array of fields that are validated against `ContentItem` column fields. Any invalid requested field will raise a `400`.

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
