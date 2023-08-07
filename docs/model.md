# Publishing API's Model

# Contents

- [Introduction](#introduction)
  - [content_id](#content_id)
  - [Diagram](#diagram)
- [Content](#content)
  - [Document](#document)
  - [Edition](#edition)
    - [Workflow](#workflow)
    - [Uniqueness](#uniqueness)
    - [Substitution](#substitution)
  - [Unpublishing](#unpublishing)
  - [ChangeNote](#changenote)
  - [AccessLimit](#accesslimit)
  - [PathReservation](#pathreservation)
- [Linking](#linking)
  - [LinkSet](#linkset)
  - [Link](#link)
- [History](#history)
  - [Event](#event)
  - [Action](#action)

# Introduction

This document serves as a broad introduction to the domain models used in
the Publishing API and their respective purposes. They can be separated into
3 areas of concern:

- [Content](#content) - Content that is stored in the Publishing API.
- [Linking](#linking) - Links between content that is stored.
- [History](#history) - The storing of operations that may have altered content
  or links.

These areas are all interconnected through the use of shared `content_id`
fields.

## content_id

`content_id` is a [UUID][uuid] value that is used to identify distinct pieces
of content that are used on GOV.UK. It is generated from within a publishing
application and the same `content_id` is used for content that is available in
multiple translations. Different iterations of the same piece of content all
share the same `content_id`.

Each piece of content stored in the Publishing API is associated with a
`content_id`, the links stored are relationships between `content_ids`, and
history is associated with a `content_id`.

## Diagram

The following is a high-level diagram that was generated with
[plantuml](http://plantuml.com/plantuml/). The
[source](model/object-model.plantuml) that generated this diagram is checked
into this repository.

![Diagram of the object model](model/object-model.png)

# Content

## Document

A document represents all iterations of a piece of content in a particular
locale. It is associated with multiple editions that represent distinct
versions of a piece of content.

The concerns of a document are which iterations are represented on draft and
live content stores; and the [lock version][optimistic-locking] for the content.

A document stores the [`content_id`](#content_id), locale and lock version for
content. It is designed to be a simple model so that it can be used for
database level locking of concurrent requests.

## Edition

An edition is a particular iteration of a piece of content. It stores most
of the data that is used to represent content in the content store and is
associated with a document. There are [uniqueness constraints](#uniqueness)
to ensure there are not conflicting Editions. Previously an Edition was named
ContentItem.

Most of the fields stored on an edition are defined as part of the
[/put-content/:content_id][put-content-api] API.

Key fields that are set internally by the Publishing API are:

- `state` - where an edition is in its [publishing workflow](#workflow), can
  be "draft", "published", "unpublished" or "superseded".
- `user_facing_version` - an integer that stores which iteration of a document
  an edition is.
- `content_store` - indicates whether an edition is intended for draft, live or
  no content store (for [substituted](#substitution) or superseded editions).

Documents that have an edition with a "live" `content_store` value will have
the corresponding edition presented on the live content store.
All documents where there is an edition with a "draft" or "live" value of
`content_store` are presented on the draft content store. With the draft
edition presented if available, otherwise the live one.

### Workflow

An edition can be in one of four states: "draft", "published", "unpublished"
and "superseded".

At any one time a document can contain:

- **1 edition** in a "draft" state
- **1 edition** in a "published" or "unpublished" state
- **any number of editions** in a "superseded" state

When the first edition of a document is created it is in a "draft" state and
available on the draft content store. The content can be updated any number of
times before publishing.

Once an edition has been published it is possible to create a new edition of
the draft - thereby having 1 draft edition and 1 published edition of a
document.

A published edition can be unpublished, which will create an
[`unpublishing`](#unpublishing) for the edition. The unpublished edition will
be represented on the live content store.

If a draft is published while there is already a published or unpublished
edition. The previous edition will have its `state` updated to "superseded"
and will be replaced on the live content store with the newly published
edition.

### Uniqueness

There are uniqueness constraints to ensure conflicting editions cannot be
stored:

- **No two editions can share the same `base_path` and `content_store` values.**
  This ensures there can't be multiple documents that are trying to use the
  same path on GOV.UK.
- **For a document there can't be two editions with the same `user_facing_version`.**
  This prevents there being two editions sharing the same version number.
- **For a document there can't be two editions on the same content store.** This
  prevents an edition being accidentally available in multiple versions in
  multiple places.

### Substitution

When creating and publishing editions an existing edition with the
same base_path will be blocked due to [uniqueness constraints](#uniqueness).
However when one of the items that conflicts is considered substitutable
(typically a non-content type) the operation can continue and the blocking item
will be discarded, in the case of a draft; or [unpublished](#unpublishing) if it
is published.

## Unpublishing

When an edition is unpublished an Unpublishing model is used to represent the
type of unpublishing and associated meta data so that the unpublished edition
can be represented correctly in the content store.

There are 5 types an unpublishing can be:

- **`withdrawal`** - The edition will still be readable on GOV.UK but will have a
  withdrawn banner, provided with an `explanation` and an optional
  `alternative_path`.
- **`redirect`** - Attempts to access the edition on GOV.UK will be redirected
  to according to the `redirects` hash, or a provided `alternative_path`
- **`gone`** - Attempts to access the edition on GOV.UK will receive a 410 Gone
  HTTP response.
- **`vanish`** - Attempts to access the edition on GOV.UK will receive a 404 Not
  Found HTTP response.
- **`substitute`** - This type cannot be set by a user and is automatically
  created when an edition is [substituted](#substitution).

## ChangeNote

An Edition can be associated with a ChangeNote, which stores a note describing
the changes that have occurred between major editions of a Document and the
time the changes occurred.

When presenting an edition of a Document to the content store, the change notes
for that edition and all previous editions are combined to create a list of
the change notes for the document.

## AccessLimit

AccessLimit is a concept that is associated with an Edition in a
"draft" state. It is used to store a list of user id's (UIDs that represent
users in [signon][signon]) which will be the only users who can view the
Edition in the draft environment.

## PathReservation

A PathReservation is a model that associates a path (in the URI context of
`https://gov.uk/<path>`) with a publishing application. This model is used to
restrict the usage of paths to a particular publishing application.

These are created when content is created or moved, and can be created
before content exists to ensure that no other app can use the path.

# Linking

Associations between content in the Publishing API is stored through `Links`,
these are used to indicate a relationship with the documents of one
[`content_id`](#content_id) with the documents of a different `content_id`.

## LinkSet

A LinkSet is a model that is used to represent the association of a
[`content_id`](#content_id) and a collection of [Links](#link).

It stores a lock version number for usage in
[optimist locking][optimistic-locking].

## Link

A Link represents the association to another `content_id` - known as the
`target_content_id`. A `link_type` and ordering is also stored on a Link.
`link_type` is used to represent the relationship between the content of
the content_id. It is common for a link to have multiple relationships to
content of the same `link_type`, the ordering field is used to store the order
in which the links of a certain `link_type` was specified. The source of a link
can either be a `LinkSet` (i.e. a `content_id`), known as
[link set links][link-set-links] or an `Edition`, known as
[edition links][edition-links].

# History

The Publishing API stores information on operations that change the state of
data stored in the Publishing API. These are stored through the Event and
Action models.

## Event

An Event is used to store the details of data that may change state within the
Publishing API. It stores data that identifies the end user and web request that
initiated the operation; which operation and which content will be affected;
and the payload of the input. Only operations that successfully complete are
stored as Events.

Events are used as a debugging and reference tool by developers of the
Publishing API. As they generate large amounts of data the full details of
them are not stored permanently.

Events older then a month are archived to S3, you can import these events back
into your local DB by running the rake tasks in lib/tasks/events.rake, after
you set up the relevant ENV variables. For example if you want to find all the
events that are relevant for a particular content id you can run:

```sh
rake 'events:import_content_id_events[a796ca43-021b-4960-9c99-f41bb8ef2266]'
```

## Action

An Action is used to store the change history of a piece of content in the
Publishing API. They are associated with both a [`content_id`](#content_id) and
an [Edition](#edition). Requests that change the state in the Publishing API
create Actions that store which action was performed and the end user who
initiated the request.

Actions can be created by publishing applications to store additional data
on the workflow of content.

[uuid]: https://en.wikipedia.org/wiki/Universally_unique_identifier
[optimistic-locking]: api.md#optimistic-locking-previous_version
[signon]: https://github.com/alphagov/signon
[put-content-api]: api.md#put-v2contentcontent_id
[link-set-links]: https://github.com/alphagov/publishing-api/blob/master/docs/link-expansion.md#patch-link-set---link-set-links
[edition-links]: https://github.com/alphagov/publishing-api/blob/master/docs/link-expansion.md#put-content---edition-links
