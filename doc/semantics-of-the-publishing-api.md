## Publishing API V2 Semantics

This document explains the semantics of Publishing API V2. This includes:

- What do each of the fields mean
- What values are allowed in each field
- What is the effect of choosing one value over another

There is another document that explains the syntax for how the API should be
used. That document can be found
[here](https://docs.google.com/document/d/1zYFZFZ2TLzasgX4SZTxuQhLzqRYCk4hWKBTcb8QFIRA/edit).

---

### content_id

Example: *d296ea8e-31ad-4e0b-9deb-026da695bb65*

Required: Yes

The `content_id` is the content item’s main identifier and it forms its identity
as it travels through the pipeline. This is why requests to create and query
content items tend to be keyed by `content_id` in the URL of the request.

Each `content_id` refers to a single piece of content, with a couple of caveats:

- `content_ids` are shared across locales – the English and French versions of a
content item share a `content_id`

- `content_ids` are shared across publish states – the draft and live versions of
a content item share a `content_id`

`content_ids` are [UUIDs](https://en.wikipedia.org/wiki/Universally_unique_identifier)
and will not be accepted by the Publishing API otherwise.

Note: Previously, the `base_path` was a content item's main identifier. This is
no longer the case. It has been changed to `content_id` because `base_paths` had
a tendency to change.

---

### base_path

Example: */vat-rates*

Required: Yes

The `base_path` specifies the route at which the content item will be served on
the GOV.UK website. Content items must have unique `base_paths` and the
Publishing API will not accept the request if this is not the case. This
uniqueness constraint extends to locale, as well. The English and French version
of a content item must have different `base_paths`.

---

### format

Examples: *manual, policy, redirect*

Required: Yes

The `format` specifies the data format of the content item as per the
[GOV.UK content schemas](https://github.com/alphagov/govuk-content-schemas).
It is used downstream to render the content item in the manner
it was intended.

If the `format` is one of either *redirect* or *gone*, the content item is
considered non-renderable and this waives the requirement for some of the other
fields in the content item to be present, namely `title`, `rendering_app` and
`public_updated_at`.

At present, not all content goes through the publishing pipeline, but there is
still a need to link to content items on our legacy infrastructure. There are
some special formats that can be used in these cases. The `format` should be
prefixed with *placeholder_* or set to *placeholder*. See
[here](https://github.com/alphagov/content-store/blob/master/doc/placeholder_item.md)
for more information.

---

### title

Example: *VAT rates*

Required: Conditionally

The `title` names the content item. It is required except in cases where the
content item is non-renderable (see **format**).

---

### description

Example: *VAT rates for goods and services*

Required: No

The `description` captures a short explanation of the content item. It is sent
downstream to the content store and may be displayed at the discretion of the
front-end application, when the content item is rendered.

---

### need_ids

Example: *["1234", "1235"]*

Required: No

The `needs_ids` are the identifiers of [user needs](https://www.gov.uk/design-principles)
that are entered through the [Maslow Application](https://github.com/alphagov/maslow).
They are passed through to the content store, untouched by the pipeline. The
front-end applications can then use the `needs_ids` to present pages to users,
such as [this one](https://www.gov.uk/info/overseas-passports).

---

### public_updated_at

Example: *2015-01-01T12:00:00Z*

Required: Conditionally

The `public_updated_at` records the last time the content item was updated. This
is the time that will appear alongside the content item in the front-end to
inform users of the time at which that particular content item was updated.

The `public_updated_at` is required except in cases where the content item is
non-renderable (see **format**). This will not be set automatically and must be
provided by the publishing application.

Note: This is subject to change. It may be that we automatically set
`public_updated_at` on behalf of publishing applications in the future. Please
speak to the Publishing Platform team if you have questions about this.

---

### publishing_app

Example: *collections-publisher*

Required: Yes

The `publishing_app` identifies the application that is responsible for
publishing the content item. When a content item is created, its `base_path` is
registered to the `publising_app`. The path may not be used by a content item
that was created with a different `publishing_app`.

The `publishing_app` can then be used to filter content items appropriately when
requests are made to the Publishing API. The `publishing_app` is also used as a
means of auditing which applications are making use of the publishing pipeline.

Note: `publishing_app` should be hyphenated as this is the convention used in
the Router API.

---

### rendering_app

Example: *government-frontend*

Required: Conditionally

The `rendering_app` identifies the front-end application that is responsible for
rendering the content item. Front-end applications will provide this string when
querying the content store.

The `rendering_app` is required except in cases where the content item is
non-renderable (see **format**).

---

### locale

Example: *en*

Required: No

The `locale` is the language in which the content item is written. Front-end
applications will optionally provide this string when querying the content store
in order to retrieve content items in a given `locale`.

A list of valid locales can be viewed in the Publishing API [here](https://github.com/alphagov/publishing-api/blob/master/config/application.rb#L32-L37).
This field is not required and if a `locale` is not provided, it will be set to
*en* automatically.

---

### phase

Examples: *alpha, beta, live*

Required: No

The `phase` is an optional field that may be used to indicate the ‘Service
Design Phase’ of the content item. The phase must be one of either *alpha*,
*beta* or *live*. If the `phase` is not specified, the Publishing API will
default it to *live*.

Content items will be published to the content store regardless of their
`phase`.  If a content item has a `phase` of either *alpha* or *beta*, a visual
component will be added to the front-end to show this (assuming the front-end
application for that format supports this).

There is more information on what each of the phases mean [here](https://www.gov.uk/service-manual/phases).

---

### details

Example: *{ body: "Something about VAT” }*

Required: Conditionally

The `details` (sometimes referred to as “details hash”) contains content and
other attributes that are specific to the `format` of the content item. The
[GOV.UK content schemas](https://github.com/alphagov/govuk-content-schemas)
determine which fields appear in the details and which are required. The details
can contain arbitrary JSON that will be stored against the content item.

Not all `formats` have required fields and so details is not required unless the
`format` demands it. If it is not set, it will default to an empty JSON object.

---

### routes

Example: *[{ path: “/vat-rates”, type: "exact" }]*

Required: Conditionally

The `routes` are used to configure the GOV.UK router for the content item. The
`routes` appear as a JSON array and each element in this array is a JSON object
that contains the properties *path* and *type*. No other properties are
supported.  The *type* must be set to *exact* to denote that the route maps to
an exact path on the GOV.UK website.

The `routes` are generally required, except for the case when the content item
has a `format` of *redirect*. In this case, the `routes` must not be present as
it doesn’t make sense to have routes for a redirect. When the `format` is
anything except *redirect*, the routes must include the `base_path` of the
content item, at the very least.

If additional `routes` are specified other than the one for the `base_path`, all
of these `routes` must reside under the `base_path`. Here is an example:

```
[
  { path: “/vat-rates”, type: "exact" },
  { path: “/vat-rates/tax-thresholds”, type: "exact" },
  { path: “/vat-rates/more-resources”, type: "exact" }
]
```

Note: Collectively, routes and redirects must have unique paths. The Publishing
API will not accept content items where the routes and redirects conflict with
each other.

---

### redirects

Example: *[{ path: “/vat-rates/tax-thresholds”, type: "exact", destination: “/vat-rates/bands” }]*

Required: Conditionally

The `redirects` are used to configure the GOV.UK router to specify redirects
related to the content item. The `redirects` appear as a JSON array and each
element in this array is a JSON object that contains the properties *path*,
*type* and *destination*. No other properties are supported. The *type* must be
set to one of either *exact* or *prefix*.

An *exact type* denotes that the *path* should be checked for an exact match
against the user’s request URL when determining whether a redirect should occur.
A *prefix type* denotes that any subpath under the specified path should be
redirected to the destination. You can think of these as “exact” and “fuzzy”
matches, respectively.

The `redirects` are generally optional, except for the case when the content
item has a `format` of *redirect*. In this case, the redirects must be present
and they must include the `base_path` of content_item in the *path* property, at
the very least.

Redirects are subject to the same requirement as routes in that their paths must
reside under the `base_path` of the content item (see **routes**).

Note: Collectively, routes and redirects must have unique paths. The Publishing
API will not accept content items where the routes and redirects conflict with
each other.

---

### update_type

Example: *major*

Required: Conditionally

The `update_type` is an indicator of how much the content item has changed since
the last time it was published. This field is required when publishing the
content item.

There’s no restriction on what the `update_type` should be, but at present we
use:

- *minor* - for minor edits that probably won’t be of interest to users

- *major* - for major edits that probably will be of interest to users

- *republish* - for when the content item needs to be re-sent to downstream
systems

- *links* - for when only the links of the content item have changed

An example case for when a republish `update_type` should be used is when there
had previously been a problem with a downstream system and that system did not
act on publish events correctly. For example, there could have been a problem
with sending email alerts and so one way that this could be rectified might be
to republish the content items.

The *links* `update_type` is set automatically when the /links endpoint is used.
There is no need to set this manually. All of these `update_types` form part of
the routing key when the content item document is placed on the message queue,
together with the `format` of the content item (e.g. *policy.major*)

---

### access_limited

Example: *{ users: ["bf3e4b4f-f02d-4658-95a7-df7c74cd0f50"] }*

Required: No

The `access_limited` field determines who should be granted access to the
content item before it has been published. At the point of publish the content
item is public and everyone has access to it. This field should be used when a
content item needs to be drafted, but it should not be visible on
content-preview (and become public knowledge) until a publish occurs.

The value of this field should be set to a JSON object that contains the key
*users* and a value that is an array of [UUIDs](https://en.wikipedia.org/wiki/Universally_unique_identifier).
These are the users that should be granted access to the content item. At
present, the only supported key is *users*.  If `access_limited` is not set, no
access restriction will be placed on the content item.

When front-end applications make requests to the content store, they must supply
the user they are making the request on behalf of if the content item is
restricted. An authentication proxy, that sits in front of the content store,
will reject the request if the supplied UUID is not in the list of
`access_limited` *users* for the content item.

---

### analytics_identifier

Example: *GDS01*

Required: No

The `analytics_identifier` is the identifier that is used to track the content
item in analytics software. The front-end applications are responsible for
rendering the `analytics_identifier` in the metadata of the page (if present) so
that information about user activity can be tracked for the content item.

---

### links

Example: *{ “related”: [“8242a29f-8ad1-4fbe-9f71-f9e57ea5f1ea”] }*

The `links` contain the [UUIDs](https://en.wikipedia.org/wiki/Universally_unique_identifier)
of other content items that this content item links to. For example, if a
content item has some attachments or contacts that it references, these content
items should appear in the `links` of the content item.

The `links` for content items are managed separately to the content item itself.
When changing `links`, it is not necessary to republish the content item.
Instead, these changes will immediately be sent downstream to the draft content
store and also to the live content store if the content item has previously been
published.

An update to the `links` causes a message to be placed on the message queue.
This message will have a special update_type of links (see **update_type**).
This queue is consumed by the Rummager application in order to reindex the
appropriate content when `links` change for a content item.

---

Is there anything wrong with the documentation? If so:

- Open a pull request
- Speak to the Publishing Platform team
