# Publishing API's API

This is the primary interface from publishing apps to the publishing pipeline.
Applications PUT items as JSON conforming to a schema specified in
[govuk-content-schemas][govuk-content-schemas-repo].

Content locations are arbitrated internally by the Publishing API, the content
is then forwarded to the live and draft content stores, and placed on the
message queue for other apps (e.g. `email-alert-service`) to consume.

## Endpoints

- [`PUT /v2/content/:content_id`](#put-v2contentcontent_id)
- [`POST /v2/content/:content_id/publish`](#post-v2contentcontent_idpublish)
- [`POST /v2/content/:content_id/unpublish`](#post-v2contentcontent_idunpublish)
- [`POST /v2/content/:content_id/discard-draft`](#post-v2contentcontent_iddiscard-draft)
- [`POST /v2/content/:content_id/import`](#post-v2contentcontent_idimport)
- [`GET /v2/content`](#get-v2content)
- [`GET /v2/content/:content_id`](#get-v2contentcontent_id)
- [`POST /v2/actions/:content_id`](#post-v2actionscontent_id)
- [`PATCH /v2/links/:content_id`](#patch-v2linkscontent_id)
- [`GET /v2/links/:content_id`](#get-v2linkscontent_id)
- [`GET /v2/expanded-links/:content_id`](#get-v2expanded-linkscontent_id)
- [`GET /v2/linked/:content_id`](#get-v2linkedcontent_id)
- [`GET /v2/linkables`](#get-v2linkables)
- [`POST /lookup-by-base-path`](#post-lookup-by-base-path)
- [`PUT /paths/:base_path`](#put-pathsbase_path)
- [`GET /debug/:content_id`](#get-debugcontent_id)

### Optimistic locking (`previous_version`)

All PUT and POST endpoints take an optional JSON attribute `previous_version`
in the request. If given, the corresponding value should be a integer. This
allows the Publishing API to check that the publishing app sending the request
intends to update the latest lock version of the model in question.

If `previous_version` is provided, the Publishing API will confirm that the
provided value matches that of the edition in the Publishing API. If it
does not, a 409 Conflict response will be provided.

### Warnings

Some endpoints may return warnings along with the content. For
those that do, in the top level object for the content, there
will be a value named "warnings". This will be an object, where the
names are the warnings that are applicable, and the corresponding
values are a human readable description of the warning.

#### Content Item Blocking Publish

This warning is only applicable for documents with an edition in a draft state,
and indicates that the draft cannot be published due to the presence of an
edition of a different at the base_path this edition is using.

Some document types are exempt from this restriction, and if either the draft,
or the blocking edition are of a "substitutable" document type, upon the
publish of the draft, the blocking item will be unpublished.

## `PUT /v2/content/:content_id`

[Request/Response detail][put-content-pact]

Used to create or update a draft edition of a document. It will restrict
creation if there is different document with a draft edition using the same
`base_path`. Uses [optimistic-locking][optimistic-locking].

The request must conform to the schema defined in govuk-content-schemas if it
does not a 422 response will be returned.

If the request is successful, this endpoint will respond with the
presented edition and [warnings](#warnings).

### Path parameters

- [`content_id`](model.md#content_id)
  - Specifies the `content_id` of the content to be created or updated.

### JSON attributes

- `access_limited` *(optional)*
  - A JSON object with a key of "users" the value of which is a array of UUIDs
    identifying users.
  - If provided, only the specified users will be able to view the content item
    on the draft frontend applications. It has no effect on live content.
- `analytics_identifier` *(optional)*
  - An identifier to track the content item in analytics software.
- `base_path` *(conditionally required)*
  - Required if `schema_name` is not one of "contact" or "government".
  - The path that this item will use on [GOV.UK](https://www.gov.uk).
- `change_note` *(optional)*
  - Specifies the [change note](model.md#changenote).
  - Ignored if the `update_type` is not major.
- `description` *(optional)*
  - A description of the content that can be displayed publicly.
- `details` *(conditionally required, default: {})*
  - JSON object representing data specific to the `document_type`.
  - **Deprecated**: If there is no top-level `change_note` attribute,
    and this is a "major" `update_type`, then the Publishing API may
    extract the `change_note` from the details hash. This behaviour is
    for backwards compatibility, the top-level `change_note` attribute
    should be used instead.
	- If `details` has a member named `change_note`, that is used.
	- Otherwise, if `details` contains a member named
      `change_history`, then the `note` with the latest corresponding
      `public_timestamp` is used.
- `document_type` *(required)*
  - A particular type of document, used to differentiate between documents that
    are of different types but share the same schema.
- `last_edited_at` *(optional)*
  - An [RFC 3339][rfc-3339] formatted timestamp should be provided, although
    [other formats][to-time-docs] may be accepted.
  - Specifies when this edition was last edited.
  - If omitted and `update_type` is "major" or "minor" `last_edited_at` will be
    set to the current time.
- `links` *(optional, default: {})*
  - A JSON object containing arrays of [`content_id`](model.md#content_id)s for
    each `link_type`.
  - Applicable `link_type`s are defined in the schema for this document_type.
- `locale` *(optional, default: "en")*
  - Accepts: An available locale from the [Rails I18n gem][i18n-gem]
  - Specifies the locale of the edition.
- `need_ids` *(optional)*
  - An array of user need ids from the [Maslow application][maslow-repo]
- `phase` *(optional, default: "live")*
  - Accepts: "alpha", "beta", "live"
- `previous_version` *(optional, recommended)*
  - Used to ensure that the most recent version of the draft is being updated.
- `public_updated_at` *(conditionally required)*
  - Required if `document_type` is not "contact" or "government".
  - An [RFC 3339][rfc-3339] formatted timestamp should be provided, although
    [other formats][to-time-docs] may be accepted.
  - The publicly shown date that this edition was last edited at.
- `publishing_app` *(required)*
  - The hostname for the publishing application that has sent this content.
- `redirects` *(conditionally required)*
  - Required for a `document_type` of "redirect".
  - An array of redirect values. (TODO: link directly to example)
- `rendering_app` *(conditionally required)*
  - Required for a `document_type` (or `format`) that is not "redirect" or
    "gone".
  - The hostname for the frontend application that will eventually render this
    content.
- `routes` *(conditionally required)*
  - Required for a `document_type` that is not "redirect".
  - An array of route values.
- `schema_name` *(required)*
  - The name of the [GOV.UK content schema][govuk-content-schemas-repo]
    that the request body will be validated against.
- `title` *(conditionally required)*
  - Required for a `document_type` that is not "redirect" or "gone".
- `update_type` *(optional)*
  - Accepts: "major", "minor", "republish"

### State changes

- If a `base_path` is provided it is reserved for use of the given
  `publishing_app`.
- Any draft editions for different documents that have a matching `base_path`
  and have a document_type of "coming soon", "gone", "redirect" or
  "unpublishing" will be deleted.
- If an edition for this document already exists in a "draft" state:
  - The existing draft edition will be updated.
  - If the `base_path` has changed since the last update, a draft redirect
    will be created.
- If an edition for this document does not exist in a "draft" state:
  - A new edition will be created
  - If the `base_path` is different to that of the published edition (if this
    exists) a draft redirect will be created.
- The draft content store will be updated with the edition and any associated
  redirects.

## `POST /v2/content/:content_id/publish`

[Request/Response detail][publish-pact]

Transitions an edition from a draft state to a published state. The edition
will be presented in the live content store. Uses
[optimistic-locking](#optimistic-locking-previous_version).

### Path parameters

- [`content_id`](model.md#content_id)
  - Identifies the document which has an edition to publish.

### JSON attributes

- `update_type` *(conditionally required)*
  - Accepts: "major", "minor", "republish"
  - Will fallback to the `update_type` set when the draft was created if not
    specified in the request.
- `locale` *(optional, default: "en")*
  - Accepts: An available locale from the [Rails I18n gem][i18n-gem]
  - Specifies the locale of the document.
- `previous_version` *(optional, recommended)*
  - Used to ensure that the version being published is the most recent draft
    update to the document.

### State changes

- The draft edition for a document matching `content_id` and `locale` will
  change state to "published"
- Any previously published editions for this document will have their state set
  to "superseded".
- For an `update_type` of "major" the `public_updated_at` field will be updated
  to the current time.
- For an `update_type` other than "major":
  - If it exists, the [change note](model.md#changenote) will be
    deleted, as change notes are only for major updates.
- If the edition has a non-blank `base_path`:
  - If the `base_path` of the draft item differs to the published version of
    this edition:
    - Redirects to this edition will be published.
  - Any published editions that have a matching `base_path` and have a
    document_type of "coming soon", "gone", "redirect" or "unpublishing" will
    have their state changed to "unpublished" with a type
    of "substitute".
  - The live content store will be updated with the published edition and any
    associated redirects.
  - All published editions that link to this item (directly or through a
    recursive chain of links) will be updated in the live content store.

## `POST /v2/content/:content_id/unpublish`

[Request/Response detail][unpublish-pact]

Transitions an edition of a document into an unpublished state. The edition will
be updated or removed from the live content store depending on the unpublishing
type. Uses [optimistic-locking][optimistic-locking].

### Path parameters

- [`content_id`](model.md#content_id)
  - Identifies the document which will have an edition unpublished.

### JSON attributes

- `allow_draft` *(optional)*
  - Boolean value, cannot be `true` if `discard_drafts` is also `true`.
  - Specifies that only a draft edition will be unpublished.
- `alternative_path` *(conditionally required)*
  - Required for a `type` of "redirect" (if `redirects` is not given), Optional for a `type` of "gone".
  - If specified, this should be a `base_path`.
- `redirects` *(conditionally required)*
  - Required for a `document_type` of "redirect" (if `alternative_path` is not given).
  - An array of redirect values similar to that which can be passed to [`PUT /v2/content/:content_id`](#put-v2contentcontent_id).
- `discard_drafts` *(optional)*
  - Boolean value, cannot be `true` if `allow_drafts` is also `true`.
  - Specifies that if a draft exists, it will be discarded.
- `explanation` *(conditionally required)*
  - Required for a `type` of "withdrawal", Optional for a type of "gone".
  - Message that will be displayed publicly on the page that has been unpublished.
- `locale` *(optional, default: "en")*
  - Accepts: An available locale from the [Rails I18n gem][i18n-gem]
  - Specifies the document to unpublish.
- `previous_version` *(optional, recommended)*
  - Used to ensure that the version being unpublished is the most recent
    version of the document.
- `type` *(required)*
  - Accepts: "gone", "redirect", "withdrawal", "vanish"
  - The type of unpublishing that is being performed.
- `unpublished_at` *(optional)*
  - An [RFC 3339][rfc-3339] formatted timestamp should be provided, although
    [other formats][to-time-docs] may be accepted.
  - Specifies when this edition was withdrawn. Ignored for unpublishing
    types other than `withdrawn`.
  - If omitted, the `withdrawn_at` time will be taken to be the time this call
    was made.


### State changes

- If the unpublishing `type` is "gone", "redirect" or "withdrawal":
  - If the document matching `content_id` and `locale` has a draft state and
    `allow_draft` is `true`:
    - The draft edition state is set to "unpublished".
    - If a previously published version of the edition exists it's state
      will be set to "superseded".
  - If the document matching `content_id` and `locale` has a draft and
    `discard_drafts` is `true`:
    - The draft edition will be deleted from the Publishing API.
    - The draft edition will be removed from the draft content store.
    - The published edition state is set to "unpublished".
  - If the document matching `content_id` and `locale` has no draft:
    - The published edition state is set to "unpublished".
  - The live content store will be updated with the unpublished edition.
  - All published editions that link to this item (directly or through a
    recursive chain of links) will be updated in the live content store.
- If the unpublishing `type` is "vanish":
  - The edition will be removed from the live content store.

## `POST /v2/content/:content_id/discard-draft`

[Request/Response detail][discard-draft-pact]

Deletes a draft edition of a document. Replaces the draft content item on
the draft content store with the published item, if one exists. Uses
[optimistic-locking][optimistic-locking].

### Path parameters

- [`content_id`](model.md#content_id)
  - Identifies the document with a draft edition.

### JSON attributes

- `locale` *(optional, default: "en")*
  - Accepts: An available locale from the [Rails I18n gem][i18n-gem]
  - With content_id, specifies the document with a draft edition.
- `previous_version` *(optional, recommended)*
  - Used to ensure the edition being discarded is the current draft.

### State changes

- The draft edition will be deleted from the Publishing API.
- The draft edition will be removed from the draft content store.
- If a published edition exists it will be added to the draft content store.

## `POST /v2/content/:content_id/import`
**Temporary Endpoint**

The import endpoint is a temporary endpoint added for the usage of importing
Maslow. This endpoint is expected to be removed by March 2017.

We are planning to introduce an import endpoint in Q4 2016, however this may
have a different API.

## `GET /v2/content`

[Request/Response detail][index-content-pact]

Retrieves a paginated list of editions for the provided query string
parameters. If editions exists in both a published and a draft for a document
and a state has been specified, the draft is returned.

### Query string parameters

- `document_type` *(optional)*
  - The type of editions to return.
- `fields[]` *(optional)*
  - Accepts an array of: "analytics_identifier", "base_path",
    "content_id", "description", "document_type", "locale",
    "public_updated_at", "schema_name", "title"
  - Determines which fields will be returned in the response, if omitted all
    fields will be returned.
- `link_*` *(optional)*
  - Accepts a content_id.
  - Used to restrict documents to those linking to another document,
    e.g. `link_organisations=056a9ff6-2ed1-4942-9f06-92df03da741d`
    will restrict the documents returned to those that have a link
    with type `organisations` to the document with specified content
    id. Query parameters matching this form can be specified multiple
    times.
- `locale` *(optional, default "en")*
  - Accepts: An available locale from the [Rails I18n gem][i18n-gem]
  - Used to restrict documents to a given locale.
- `order` *(optional, default: "-public_updated_at")*
  - The field to sort the results by.
  - Returned in an ascending order unless prefixed with a hyphen, e.g.
    "-base_path".
- `page` *(optional, default: 1)*
  - The page of results requested.
- `per_page` *(optional, default: 50)*
  - The number of results to be shown on a given page.
- `q` *(optional)*
  - Search term to match against the fields in `search_in[]`.
- `search_in[]` *(optional, default: [title, base_path])*
  - Array of fields to search against.
  - Fields supported are `title`, `base_path`, `description`, and `details.*` -
    where * indicates a field within details, e.g. `details.internal_name`.
- `publishing_app` *(optional)*
  - Used to restrict editions to those for a given publishing app.
- `states` *(optional)*
  - Used to restrict editions to those in the specified states.

## `GET /v2/content/:content_id`

[Request/Response detail][show-content-pact]

Retrieves a single edition of a document for a `content_id` and `locale`. By
default the most recent edition is returned, which may be a draft.

If the returned item is in the draft state, [warnings](#warnings) may be
included within the response.

### Path parameters

- [`content_id`](model.md#content_id)
  - Identifies the document to be returned.

### Query string parameters

- `locale` *(optional, default "en")*
  - Accepts: An available locale from the [Rails I18n gem][i18n-gem]
  - Used to return a specific locale.
- `version` *(optional)*
  - Specify a particular edition of this document
  - If omitted the most recent edition.

## `POST /v2/actions/:content_id`

TODO: Request/Response pact for actions

**Note - The usage opportunities for this endpoint is currently in discovery,
this feature may change significantly in time.**

Creates an action for the document that is specified, defaults to
targeting a draft edition but can be specified to target
live version. Uses [optimistic-locking][optimistic-locking].

### Path parameters

- [`content_id`](model.md#content_id)
  - Identifies the document of which edition will be targeted.

### JSON attributes

- `action` *(required)*
  - Currently an arbitrary name describing the workflow a edition has gone
    through
  - Provided in CamelCase
- `draft` *(optional, default: "true")*
  - Whether to target the live or draft edition of a document.
- `locale` *(optional, default: "en")*
  - Accepts: An available locale from the [Rails I18n gem][i18n-gem]
  - Specifies which locale of a document to delete.
- `previous_version` *(optional, recommended)*
  - Used to ensure the document hasn't been updated before sending this request

## `PATCH /v2/links/:content_id`

[Request/Response detail][patch-link-set-pact]

Creates or updates a set of links for the given `content_id`. Link sets can be
created before or after the [PUT request](#put_v2contentcontent-id) for the
content. These are tied to documents solely by matching `content_id` and they
are not associated with a locale or a particular edition. The ordering of links
in the request is preserved.

### Path parameters

- [`content_id`](model.md#content_id)
  - Identifies the documents the links are for.

### JSON attributes

- `links` *(required)*
  - A JSON object containing arrays of [`content_id`](model.md#content_id)s for
    each `link_type`.
  - An empty array for a `link_type` will delete that `link_type`.

```json
  {
    "links": {
      "organisations": [
        "591436ab-c2ae-416f-a3c5-1901d633fbfb"
      ],
      "unwanted_link_type": []
    }
  }
```
- `previous_version` *(optional, recommended)*
  - Used to ensure that we are updating the current version of the link set.

### State changes

- A link set is created or updated, with the `lock_version` of the link set
  being incremented.
- The draft content store is updated if there are editions of documents
  matching the `content_id` on the draft content store.
- The live content store is updated if there are editions of documents
  matching the `content_id` on the live content store.

## `GET /v2/links/:content_id`

[Request/Response detail][show-links-pact]

Retrieves only the [link set links][link-set-links] for the given `content_id`.
Returns arrays of `content_id`s representing documents. These are grouped by
`link_type`. The ordering of the returned links matches the ordering when they
were created.

### Path parameters

- [`content_id`](model.md#content_id)
  - Identifies the documents links will be retrieved for.

## `GET /v2/expanded-links/:content_id`

[Request/Response detail][show-expanded-links-pact]

Retrieves the expanded link set for the given `content_id`. Returns arrays of
details for each linked edition in groupings of `link_type`.

### Path parameters

- [`content_id`](model.md#content_id)
  - Identifies the link set links will be retrieved for.

### Query string parameters:

- `with_drafts` *(optional, default: true)*
  - Whether links to draft editions should be included in the response.

## `GET /v2/linked/:content_id`

 [Request/Response detail][show-linked-pact]

Retrieves all editions that have [link set links][link-set-links] to the given `content_id`
for some `link_type`.

### Path parameters

- [`content_id`](model.md#content_id)
  - Identifies the link set editions may be linked to.

### Query string parameters

- `link_type` *(required)*
  - The type of link between the documents.
- `fields[]` *(required)*
  - Accepts an array of: "analytics_identifier", "base_path",
    "content_id", "description", "document_type", "locale",
    "public_updated_at", "schema_name", "title"
  - Determines which fields will be returned in the response.

## `GET /v2/linkables`

 [Request/Response detail][index-linkables-pact]

Returns abridged versions of all editions matching the given
`document_type`. Returns `title`, `content_id`, `publication_state`, `base_path`
from the document and edition. It also adds a special field `internal_name`,
which is `details.internal_name` and falls back to `title`.

### Query string parameters:

- `document_type` *(required)*
  - The `document_type` value that returned editions has.

## `POST /lookup-by-base-path`

 [Request/Response detail][lookup-by-base-path-pact]

Retrieves live editions for a given collection of base paths. Returns
a mapping of `base_path` to `content_id`.

### POST parameters:

- `base_paths[]` *(required)*
  - An array of `base_path`s to query by.

## `PUT /paths/:base_path`

 [Request/response detail][reserve-path-pact]

Reserves a path for a publishing application. Returns success or failure only.

### Path parameters

- `base_path`
  - Identifies the path that will be reserved

### JSON parameters:

- `publishing_app` *(required)*
  - The name of the application making this request, words separated with hyphens.
- `override_existing` *(optional)*
  - Explicitly claim a path that has already been reserved by a different
    publishing_app. If not true, attempting to do this will fail.

### State changes

- If no path reservation for the supplied base_path is present, one will be
  created for the supplied publishing_app.
- If a path reservation exists for the supplied base_path but a different
  publishing_app, and `override_existing` is not true, the command will fail.
- If a path reservation exists for the supplied base_path and a different a
  publishing_app, and `override_existing` is true, the existing reservation will
  be updated to the supplied publishing_app.

## `GET /debug/:content_id`

Displays debug information for `content_id`.

### Path parameters:

- [`content_id`](model.md#content_id)
  - Identifies the document to debug.

### Usage:

```
  ssh publishing-api-1.integration -CNL 8888:127.0.0.1:3093
```

And then open http://localhost:8888/debug/f141fa95-0d79-4aed-8429-ed223a8f106a

Alternatively add the following host to your hosts file:

```
  127.0.0.1 publishing-api.integration.publishing.service.gov.uk
```

And then open
http://publishing-api.integration.publishing.service.gov.uk:8888/debug/f141fa95-0d79-4aed-8429-ed223a8f106a

[govuk-content-schemas-repo]: https://github.com/alphagov/govuk-content-schemas
[optimistic-locking]: #optimistic-locking-previous_version
[put-content-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_from_the_Whitehall_application_to_create_a_content_item_at_/test-item_given_/test-item_has_been_reserved_by_the_Publisher_application
[iso-8601]: https://en.wikipedia.org/wiki/ISO_8601
[to-time-docs]: http://apidock.com/rails/String/to_time
[i18n-gem]: https://github.com/svenfuchs/rails-i18n
[maslow-repo]: https://github.com/alphagov/maslow
[link-set-links]: https://github.com/alphagov/publishing-api/blob/master/doc/link-expansion.md#patch-link-set---link-set-links
[publish-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_publish_request_for_version_3_given_the_content_item_bed722e6-db68-43e5-9079-063f623335a7_is_at_version_3
[unpublish-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#an_unpublish_request_given_a_published_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7
[discard-draft-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_discard_draft_content_given_a_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7
[index-content-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_get_entries_request_given_a_content_item_exists_in_multiple_locales_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7
[show-content-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_return_the_content_item_given_a_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7
[patch-link-set-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_update_the_linkset_at_version_3_given_the_linkset_for_bed722e6-db68-43e5-9079-063f623335a7_is_at_version_3
[show-links-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_get-links_request_given_empty_links_exist_for_content_id_bed722e6-db68-43e5-9079-063f623335a7
[show-expanded-links-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_get-expanded-links_request_given_empty_links_exist_for_content_id_bed722e6-db68-43e5-9079-063f623335a7
[show-linked-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_return_the_items_linked_to_it_given_no_content_exists
[index-linkables-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_get_linkables_request_given_there_is_content_with_format_'topic'
[lookup-by-base-path-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_/lookup-by-base-path-request_given_there_are_live_content_items_with_base_paths_/foo_and_/bar
[reserve-path-pact]: https://pact-broker.cloudapps.digital/pacts/provider/Publishing%20API/consumer/GDS%20API%20Adapters/latest#a_request_to_put_a_path_given_no_content_exists
[rfc-3339]: https://www.ietf.org/rfc/rfc3339.txt
