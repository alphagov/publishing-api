# Link Expansion

## Contents

- [Introduction](#introduction)
- [Example output](#example-output)
- [When it occurs](#when-it-occurs)
- [How links are added](#how-links-are-added)
  - [`patch-link-set` - Link set links](#patch-link-set---link-set-links)
  - [`put-content` - Edition links](#put-content---edition-links)
- [Types of links](#types-of-links)
  - [Available translations](#available-translations)
  - [Direct links](#direct-links)
  - [Reverse links](#reverse-links)
  - [Recursive links](#recursive-links)
    - [Recursive link paths](#recursive-link-paths)
- [Link presentation](#link-presentation)
  - [Fields](#fields)
- [Developer gotchas](#developer-gotchas)
  - [Why is this link appearing?](#why-is-this-link-appearing)
  - [Why is this link *not* appearing?](#why-is-this-link-not-appearing)
  - [Why/how does a link have extra fields?](#whyhow-does-a-link-have-extra-fields)
  - [Why does this link have/have no child links?](#why-does-this-link-havehave-no-child-links)
- [Debugging](#debugging)

## Introduction

Link expansion is a concept in the Publishing API which describes the process
of converting the stored links of an edition into a JSON representation
containing the details of these links. It is used in the Publishing API
during the process of sending an edition downstream to the
[Content Store][content-store].

The process involves determining which editions should and can be linked
to, the versions of them that are linked, and the fields that will be included
in the representation. It replaces a process in the Content Store which was
used to determine and expand links at the point of request.

A closely related process to this is
[dependency-resolution](dependency-resolution.md). This is something of a
reversal in link expansion and has the role of determining which editions
will need re-presenting to the content store as a result of an update to a
document.

## Example Output

Below is an abridged example of an edition represented as JSON after link
expansion has occurred.

```json
{
  "base_path": "/government/organisations/department-for-transport/about/welsh-language-scheme",
  "content_id": "5f54d009-7631-11e4-a3cb-005056011aef",
  ...
  "links": {
    "organisations": [{
      "analytics_identifier": "D9",
      "api_path": "/api/content/government/organisations/department-for-transport",
      "base_path": "/government/organisations/department-for-transport",
      "content_id": "4c717efc-f47b-478e-a76d-ce1ae0af1946",
      "description": null,
      "document_type": "organisation",
      "locale": "en",
      "public_updated_at": "2015-06-03T13:12:51Z",
      "schema_name": "organisation",
      "title": "Department for Transport",
      "details": {
        "brand": "department-for-transport",
        "logo": {
          "formatted_title": "Department\u003cbr/\u003efor Transport",
          "crest": "single-identity"
        }
      },
      "links": {}
    }],
    "available_translations": [{
      "analytics_identifier": null,
      "api_url": "https://www.gov.uk/api/content/government/organisations/department-for-transport/about/welsh-language-scheme",
      "base_path": "/government/organisations/department-for-transport/about/welsh-language-scheme",
      "content_id": "5f54d009-7631-11e4-a3cb-005056011aef",
      "description": "When conducting public business in Wales, English and Welsh languages are treated equally.",
      "document_type": "welsh_language_scheme",
      "locale": "en",
      "public_updated_at": "2013-06-21T13:22:34Z",
      "schema_name": "corporate_information_page",
      "title": "Welsh language scheme",
      "links": {}
    }, {
      "analytics_identifier": null,
      "api_url": "https://www.gov.uk/api/content/government/organisations/department-for-transport/about/welsh-language-scheme.cy",
      "base_path": "/government/organisations/department-for-transport/about/welsh-language-scheme.cy",
      "content_id": "5f54d009-7631-11e4-a3cb-005056011aef",
      "description": "Wrth gynnal busnes cyhoeddus yng Nghymru, ieithoedd Cymraeg a Saesneg yn cael eu trin yn gyfartal.",
      "document_type": "welsh_language_scheme",
      "locale": "cy",
      "public_updated_at": "2013-06-21T13:22:34Z",
      "schema_name": "corporate_information_page",
      "title": "Cynllun iaith Gymraeg",
      "links": {}
    }]
  },
}
```

Within a `links` JSON object there are keys which indicate the type of link
(`link_type`), and at the value of those keys is an array of all links of that
type. In the above example there are two types of link: `organisations` and
`available_translations` which contain 1 and 2 links respectively.

## When it occurs

Link expansion occurs at the point an edition is represented to the
Content Store - which is normally the result of a [Sidekiq](http://sidekiq.org/)
worker process such as [DownstreamDraftWorker][downstream-draft-worker] or
[DownstreamLiveWorker][downstream-live-worker].

## How links are added

There are two ways that links can be added for a document: link set links and
edition links. These are added by different endpoints.

### `patch-link-set` - Link set links

These links are added via the
[`patch-link-set`](api.md#patch-v2linkscontent_id) endpoint. They are
associated with a `content_id`, which therefore associates them with all
the locales of a document.

They are typically used for taxonomy based links and aren't related to the
specific content of an edition.

They do not follow a draft/published workflow, once added they will apply to
editions of a document on both draft and live content stores.

### `put-content` - Edition links

These links are added via the [`put-content`](api.md#put-v2contentcontent_id)
endpoint. They are associated with a particular edition of a document and no
other editions.

These are used for links that are associated with the content of an edition.

In cases when there are edition links and link set links which have the same
`link_type`, the edition links will take precedence during link expansion.

## Types of links

### Available translations

A document can be available in multiple translations. This will be
determined by documents sharing the same [`content_id`][content-id] and
having different [`locale`][locale] values.

The links for an edition will automatically include the available translations
of editions of documents matching the same `content_id`, including the current
locale.

**Example**

For item `E` which exists in English ("en") and Welsh ("cy") the available
translations links include a link to the "en" and "cy" variations of the
document.

### Direct links

These are the links which have been added via
[`patch-link-set`](#patch-link-set---link-set-links) and
[`put-content`](#put-content---edition-links) for a respective `content_id`
or edition. They are presented with the `link_type` provided when creating the
link.

These links may be [recursive](#recursive-links) depending on their
`link_type`.

### Reverse links

Certain `link_types` are considered reverse. When they are added for a
`content_id` or edition they are also presented as part of their target.

A reverse link corresponds with a direct link and has a reverse name. For
instance `parent` has a reverse name of `children`.

**Example**

For item `A` which has a link to `B` which is a reverse `link_type` of parent.
`A` will be presented with a link to `B` of type `parent`, whereas `B` will be
presented with a link to `A` of type `children`.

A quirk of reverse links is that they are presented with their corresponding
link. For example when presenting a collection of links with a type of
`children`, each one of those links will have a link of type `parent` which
links to the original content.

These links may be [recursive](#recursive-links) dependant on their `link_type`,
they are defined in [`LinkExpansion::Rules`][link-expansion-rules].

### Recursive links

Some link types are considered recursive which is used to present a tree
structure of links of specific types. As with many things recursive, these
link types are frequently a source of confusion.

These are used in cases where multiple levels of links are needed to render
content. A common use case for this is breadcrumbs, where we may want to know the
hierarchy from the root `/` page to the page we are in. These are represented
by using a recursive `parent` link type.

**Example**

Consider the page [Apprenticeship Standards][apprenticeship-standards] which
has breadcrumbs of "Home > Further education and skills > Apprenticeships"

- "Apprenticeship Standards" would have a link to "Apprenticeships" of type
`parent`.
- "Apprenticeships" would have a link to "Further education and skills" of type
`parent`.
- "Further education and skills" could have a link to "Home" of type `parent`.

As `parent` is a recursive link type each link would include a link to it's
subsequent parent forming a graph of:

```
"Apprenticeship Standards" -parent-> "Apprenticeships" -parent-> "Further education and skills" -parent-> "Home"
```

From which breadcrumbs can be generated.

#### Recursive link paths

Recursive links can be defined as a path of link types, which means that only
a structure of links that matches the defined path will be included in link
expansion.

An example of this is the path of `ordered_related_items`,
`mainstream_browse_pages` and `parent`. Only a tree of links that match this
path would be included in link expansion.

This path would be included in the links representation for an item `A`:

```
"Item A" -ordered_related_items-> "Item B" -mainstream_browse_pages-> "Item C" -parent-> "Item D"
```

However this path would not be:

```
"Item A" -mainstream_browse_pages-> "Item B" -ordered_related_items-> "Item C" -parent-> "Item D"
```

An item in a path of link types can be marked as _recurring_. This means that
there can be many items of this type in the path.

For the path `ordered_related_items`, `mainstream_browse_pages` and
`parent.recurring` there be any number of `parent` items, and only 1 instance
of `ordered_related_items` and `mainstream_browse_pages`.

This is a valid path for `ordered_related_items`, `mainstream_browse_pages` and `parent`:

```
"Item A" -ordered_related_items-> "Item B" -mainstream_browse_pages-> "Item C" -parent-> "Item D" -parent-> "Item E" -parent-> "Item F"
```

Yet this is invalid:

```
"Item A" -ordered_related_items-> "Item B" -mainstream_browse_pages-> "Item C" -mainstream_browse_pages-> "Item D" -parent-> "Item E" -parent-> "Item F"
```

The rules for recursive link types are defined in
[`LinkExpansion::Rules`][link-expansion-rules].

## Which states are linked

Whether an item is linked to depends on whether an edition of a document
being linked to exists in a particular [state](model.md#state). The states that
are applicable are determined by the state of the content item that link
expansion is performed for.

### Edition has a state of `published` or `unpublished`

Links are included when an editions exists in a `published` state. Editions
that are in an `unpublished` state with type `withdrawn` are linked to
depending on their `link_type`. Editions that are `unpublished` and are not of
type `withdrawn` are not linked.

The `link_types` that define whether a withdrawn edition is linked is defined
in [LinkExpansion][link-expansion].

### Edition has a state of `draft`

Editions follow the same rules as those for `published` or `unpublished`
however draft items are also included for all link types.

## Link presentation

Links are presented as a JSON object where the keys of the object are the link
types and for each link type there is an array of links.

The ordering of links is determined by the order in which the links were added
via `patch-link-set`. Automatic links do not have a specific ordering.

### Fields

By default links contain the following fields:

- `analytics_identifier` - Used to track a content item in analytics software
- `api_path` - The path to the JSON representation of this item
- `base_path` - The public path to this item
- `content_id` - A UUID to represents the document
- `description` - A short description of the content
- `document_type` - This describes a type of document used on GOV.UK and
  allowed by the schema
- `locale` - The language this document is written in
- `public_updated_at` - The date/time that this document  was last changed
- `schema_name` - The schema (in `content_schemas`) that this edition conforms to
- `title` - The title of the edition
- `links` - Any [recursive links](#recursive-links) that are presented with a
  link representation of an edition

The fields can and are customised in some cases. This can be done on a
`link_type` basis. These customisations can be performed in
[`LinkExpansion::Rules`][link-expansion-rules].

## Developer gotchas

Link expansion is complicated and thus can be challenging for developers to
understand. This section attempts to cover some of the common questions,
we're always welcome for suggestions to simplify link expansion.

### Why is this link appearing?

To understand why a link is presented the following things should be considered:

- If the link is in the `available_translations` it will be a
  [translation](#available-translations) of the document;
- The link could be a [direct link](#direct-links) from the
  [`Edition`](model.md#edition) or [`LinkSet`](model.md#linkset);
- The link could be a link defined on a different Edition or LinkSet and be
  a [reverse link](#reverse-links) and represented reciprocally;
- If the link is defined inside a different link it will be either be a
  [recursive link](#recursive-links) or be the automatic link added
  back as part of a [reverse link](#reverse-links).

### Why is this link *not* appearing?

A link that you expect to appear might not be appearing due to the following
reasons:

- The item to be linked to might not be available in a
  [linkable state](#which-states-are-linked);
- There could be [`Edition`](model.md#edition) or [`LinkSet`](model.md#linkset)
  links that are defined with the same `link_type` which means the edition
  links will take precedence.
- If a recursive link is expected it may not be following a valid
  [recursive link path](#recursive-link-paths).

### Why/how does a link have different fields to other links?

Links for a specific `link_type` can be defined to return
[different fields](#fields) as part of link expansion. These are defined in
[`LinkExpansion::Rules`][link-expansion-rules].

## Debugging

You can explore link expansion in the rails console by creating a
[`LinkExpansion`][link-expansion] instance.

```
> link_expansion = LinkExpansion.by_content_id(content_id, locale: :en, with_drafts: true)
```

You can then print the [`link_graph`][link-graph] of the link expansion to view
the links.

```
> link_expansion.link_graph.to_h
=> {:organisations=>
  [{:content_id=>"2e7868a8-38f5-4ff6-b62f-9a15d1c22d28", :links=>{}},
   {:content_id=>"b548a09f-8b35-4104-89f4-f1a40bf3136d", :links=>{}},
   {:content_id=>"de4e9dc6-cca4-43af-a594-682023b84d6c", :links=>{}},
   {:content_id=>"e8fae147-6232-4163-a3f1-1c15b755a8a4", :links=>{}}],
 :related=>[{:content_id=>"78cedbfe-d3aa-41c3-b8c0-aeb5d9035d6a", :links=>{}}]}
```

You can navigate through the `link_graph` object for further debugging
information.

[apprenticeship-standards]: https://www.gov.uk/government/collections/apprenticeship-standards
[content-id]: model.md#user-content-content_id
[content-store]: https://github.com/alphagov/content-store
[downstream-draft-worker]: ../app/workers/downstream_draft_worker.rb
[downstream-live-worker]: ../app/workers/downstream_live_worker.rb
[link-expansion]: ../lib/link_expansion.rb
[link-expansion-rules]: ../lib/expansion_rules/link_expansion.rb
[link-graph]: ../app/models/link_graph.rb
[locale]: model.md#user-content-locale
