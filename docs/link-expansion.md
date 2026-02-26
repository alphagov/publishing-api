# Links and Link Expansion

## Contents

- [Introduction](#introduction)
- [Example output](#example-output)
- [Types of Link Expansion](#type-of-link-expansion)
  - [Legacy Link Expansion](#legacy-link-expansion)
  - [GraphQL Link Expansion](#graphql-link-expansion)
- [Link lifecycles](#link-lifecycles)
  - [`put-content` - Edition links](#put-content---edition-links)
  - [`patch-link-set` - Link set links](#patch-link-set---link-set-links)
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
  - [Why/how does a link have different fields to other links?](#whyhow-does-a-link-have-different-fields-to-other-links)
- [Debugging legacy link expansion](#debugging-legacy-link-expansion)

## Introduction

Publishing API stores links between content items so that frontend applications can render links to related content on GOV.UK, such as the organisation responsible for publishing the page. These links contain only a reference to the related content item - they don't contain any information about the related content item until they are "expanded".

Link expansion is the process of converting the stored links of an edition into a JSON representation containing more information about the linked content items. The expansion process occurs at different times, depending on whether GraphQL is being used (see [Types of Link Expansion](#type-of-link-expansion)).

A closely related process to this is [dependency resolution](dependency-resolution.md), which runs immediately after a document has been presented to Content Store. This is roughly the opposite of link expansion. When a document is updated, Publishing API works out which documents link to the updated document, and presents the linked documents to Content Store with the new expanded link content. Dependency resolution is not required for GraphQL.

## Example Output

Below is an abridged example of an edition represented as JSON after link expansion has occurred.

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
  }
}
```

Within a `links` JSON object there are keys which indicate the type of link (`link_type`), and at the value of those keys is an array of all links of that type. In the above example there are two types of link: `organisations` and `available_translations` which contain 1 and 2 links respectively.

Note that `available_translations` is not submitted as part of the payload from publishing applications. It is added automatically by Publishing API to all documents. See [available translations](#available-translations).

## Type of Link Expansion

### Legacy Link Expansion

This occurs at the time of putting content, patching links and publishing a document. The links for an edition are pre-computed and presented to Content Store. Content Store caches a copy of these links in its database and renders this cached version when requested.

The definitions for which fields to include in expanded links are hardcoded in Publishing API (see [fields](#fields)).

### GraphQL Link Expansion

This occurs at the time of requesting content by the public. The links for an edition are only computed when the document is rendered to a client.

The definitions for which fields to include in expanded links are defined by the client in their request payload (see [fields](#fields)).

## Link Lifecycles

There are two categories of link with two separate API routes: edition links and link set links.

### `put-content` - Edition links

These links are added via the [`put-content`](api.md#put-v2contentcontent_id) endpoint. They are associated with a single edition of a document.

In cases when there are edition links and link set links which have the same `link_type`, the edition links will take precedence during link expansion.

Edition links should be the default approach to link creation, because link set links have the disadvantage of applying to all editions and locales of a document. Whereas edition links allow links to be set against draft editions, meaning they won't become live until the edition is published. Edition links are also locale specific, so different locales of the same Content ID can have different links.

However, edition links have a substantial limitation, which is that [recursive link expansion](#recursive-links) is not applied to them during legacy link expansion. If a document needs to access data from documents more than one link away, then link set links must be used. This is not the case with GraphQL link expansion, which expands all levels of recursive edition links. This limitation will no longer exist when legacy link expansion is switched off.

Below is an abridged example of the edition above, sent to Publishing API by a publishing application with edition links in the payload.

```json
{
  "base_path": "/government/organisations/department-for-transport/about/welsh-language-scheme",
  "content_id": "5f54d009-7631-11e4-a3cb-005056011aef",
  ...
  "links": {
    "organisations": [
      "4c717efc-f47b-478e-a76d-ce1ae0af1946"
    ],
  }
}
```

### `patch-link-set` - Link set links

Link set links pre-date edition links. These links are added via the [`patch-link-set`](api.md#patch-v2linkscontent_id) endpoint. They are associated with a `content_id` rather than an `edition_id`, which therefore means they are associated with all editions and all locales of a Content ID.

This is important because it means when a patch links request is made, **they will immediately apply to live editions** of a document, even if the document has a draft edition.

Theoretically there isn't a need for link set links to exist as edition links can serve all of the same use cases. However, edition links are missing the crucial feature of recursive expansion in legacy link expansion, so we cannot retire link set links. This will be resolved by GraphQL link expansion, which expands all levels of recursive edition links.

Below is an abridged example of a patch links request for the document above, sent to Publishing API by a publishing application.

```json
{
  "links": {
    "organisations": [
      "4c717efc-f47b-478e-a76d-ce1ae0af1946"
    ],
  }
}
```

## Types of links

### Available translations

A document can be available in multiple translations. This will be determined by documents sharing the same [`content_id`][content-id] and having different [`locale`][locale] values.

The links for an edition will automatically include the available translations of editions of documents matching the same `content_id`, including the current locale.

**Example**

For item `E` which exists in English ("en") and Welsh ("cy") the available translations links include a link to the "en" and "cy" variations of the document.

### Direct links

These are typical links which have been added via [`patch-link-set`](#patch-link-set---link-set-links) or [`put-content`](#put-content---edition-links). They are presented with the `link_type` provided when creating the link.

These links may be [recursive](#recursive-links) depending on their `link_type`.

### Reverse links

Certain `link_types` are considered the reverse of others.

These are configured in the [expansion link rules](lib/expansion_rules.rb) for legacy link expansion and the [edition type](app/graphql/types/edition_type.rb) for GraphQL link expansion.

A reverse link corresponds with a direct link and has a reverse name. For instance `parent` has a reverse name of `children`.

**Example**

For item `A` which has a link to `B` which is a reverse `link_type` of parent. `A` will be presented with a link to `B` of type `parent`, whereas `B` will be presented with a link to `A` of type `children`.

A quirk of reverse links is that they are presented with their corresponding link. For example when presenting a collection of links with a type of `children`, each one of those links will have a link of type `parent` which links to the original content.

These links may be [recursive](#recursive-links) dependant on their `link_type`, they are defined in [`LinkExpansion::Rules`][link-expansion-rules].

### Recursive links

Some link types are considered recursive. These types are used to present a tree structure of links.

Recursive links are used in cases where multiple levels of links are needed to render content. A common use case for this is breadcrumbs, where we may want to know the hierarchy from the root `/` page to the page we are on. Breadcrumbs are represented by using a recursive `parent` link type.

**Example**

Consider the page [Apprenticeship Standards][apprenticeship-standards] which has breadcrumbs of "Home > Further education and skills > Apprenticeships"

- "Apprenticeship Standards" would have a link to "Apprenticeships" of type `parent`.
- "Apprenticeships" would have a link to "Further education and skills" of type `parent`.
- "Further education and skills" could have a link to "Home" of type `parent`.

As `parent` is a recursive link type each link would include a link to its subsequent parent forming a graph of:

```
"Apprenticeship Standards" -parent-> "Apprenticeships" -parent-> "Further education and skills" -parent-> "Home"
```

From which breadcrumbs can be generated.

#### Recursive link paths

Recursive links can be defined as a path of link types, which means that only a structure of links that matches the defined path will be included in link expansion.

An example of this is the path of `ordered_related_items`, `mainstream_browse_pages` and `parent`. Only a tree of links that match this path would be included in link expansion.

This path would be included in the links representation for an item `A`:

```
"Item A" -ordered_related_items-> "Item B" -mainstream_browse_pages-> "Item C" -parent-> "Item D"
```

However this path would not be:

```
"Item A" -mainstream_browse_pages-> "Item B" -ordered_related_items-> "Item C" -parent-> "Item D"
```

An item in a path of link types can be marked as _recurring_. This means that there can be many items of this type in the path.

For the path `ordered_related_items`, `mainstream_browse_pages` and `parent.recurring` there be any number of `parent` items, and only 1 instance of `ordered_related_items` and `mainstream_browse_pages`.

This is a valid path for `ordered_related_items`, `mainstream_browse_pages` and `parent`:

```
"Item A" -ordered_related_items-> "Item B" -mainstream_browse_pages-> "Item C" -parent-> "Item D" -parent-> "Item E" -parent-> "Item F"
```

Yet this is invalid:

```
"Item A" -ordered_related_items-> "Item B" -mainstream_browse_pages-> "Item C" -mainstream_browse_pages-> "Item D" -parent-> "Item E" -parent-> "Item F"
```

For legacy link expansion, the rules for recursive link types are defined in [`LinkExpansion::Rules`][link-expansion-rules].

For GraphQL link expansion, the client defines the recursive links they would like to obtain in their query, which forms part of the request payload.

## Edition state and links

Whether a link is included during link expansion depends on which [state](model.md#state) the linked item is in.

### Edition has a state of `published` or `unpublished`

Links are included when the linked edition exists in a `published` state. Editions that are in an `unpublished` state with type `withdrawn` may be linked to depending on their `link_type`. Editions that are `unpublished` but not `withdrawn` are not linked.

The `link_types` that define whether a withdrawn edition is linked to are defined in the [Link::PERMITTED_UNPUBLISHED_LINK_TYPES constant](app/models/link.rb).

### Edition has a state of `draft`

Links to draft editions are only included if the item which is having its links expanded is also in the draft state.

## Link presentation

Links are presented as a JSON object where the keys of the object define the link types and for each link type there is an array of links.

The ordering of links is determined by the order in which the links were added via `patch-link-set`. Automatic link types (e.g. translations) do not have a specific ordering.

### Fields

#### With legacy link expansion

By default links contain the following fields:

- `analytics_identifier` - Used to track a content item in analytics software
- `api_path` - The path to the JSON representation of this item
- `base_path` - The public path to this item
- `content_id` - A UUID to represents the document
- `description` - A short description of the content
- `document_type` - This describes a type of document used on GOV.UK and allowed by the schema
- `locale` - The language this document is written in
- `public_updated_at` - The date/time that this document  was last changed
- `schema_name` - The schema (in `content_schemas`) that this edition conforms to
- `title` - The title of the edition
- `links` - Any [recursive links](#recursive-links) that are presented with a link representation of an edition

The fields can be customised per `link_type`. These customisations are defined in [`LinkExpansion::Rules`][link-expansion-rules].

#### With GraphQL link expansion

The client defines which fields they would like to obtain by including them in their query. There are no default fields.

## Developer gotchas

Link expansion is complicated and thus can be challenging for developers to understand. This section attempts to cover some of the common questions, we always welcome any suggestions to simplify link expansion.

### Why is this link appearing?

To understand why a link is presented the following things should be considered:

- If the link is an `available_translations` link it will be a [translation](#available-translations) of the document;
- The link could be a [direct link](#direct-links) from the [`Edition`](model.md#edition) or [`LinkSet`](model.md#linkset);
- The link could be a link defined on a different Edition or LinkSet and be a [reverse link](#reverse-links) and represented reciprocally;
- If the link is defined inside a different link it will be either be a [recursive link](#recursive-links) or it will be the counterpart of a [reverse link](#reverse-links).

### Why is this link *not* appearing?

A link that you expect to appear might not be appearing for one of the following reasons:

- The item to be linked to might not be available in a [linkable state](#edition-state-and-links);
- If it is a link set link, there could be [`Edition`](model.md#edition) links that are defined with the same `link_type` which means the edition links will take precedence.
- If a recursive link is expected it may not be following a valid [recursive link path](#recursive-link-paths).

### Why/how does a link have different fields to other links?

> This is relevant to legacy link expansion only. For GraphQL, the fields are defined by the client.

Links for a specific `link_type` can be defined to return [different fields](#fields) as part of link expansion. These are defined in [`LinkExpansion::Rules`][link-expansion-rules].

## Debugging legacy link expansion

You can explore legacy link expansion in the rails console by creating a [`LinkExpansion`][link-expansion] instance.

```
> link_expansion = LinkExpansion.by_content_id(content_id, locale: :en, with_drafts: true)
```

You can then print the [`link_graph`][link-graph] of the link expansion to view the links.

```
> link_expansion.link_graph.to_h
=> {:organisations=>
  [{:content_id=>"2e7868a8-38f5-4ff6-b62f-9a15d1c22d28", :links=>{}},
   {:content_id=>"b548a09f-8b35-4104-89f4-f1a40bf3136d", :links=>{}},
   {:content_id=>"de4e9dc6-cca4-43af-a594-682023b84d6c", :links=>{}},
   {:content_id=>"e8fae147-6232-4163-a3f1-1c15b755a8a4", :links=>{}}],
 :related=>[{:content_id=>"78cedbfe-d3aa-41c3-b8c0-aeb5d9035d6a", :links=>{}}]}
```

You can navigate through the `link_graph` object for further debugging information.

[apprenticeship-standards]: https://www.gov.uk/government/collections/apprenticeship-standards
[content-id]: model.md#user-content-content_id
[content-store]: https://github.com/alphagov/content-store
[link-expansion]: ../lib/link_expansion.rb
[link-expansion-rules]: ../lib/expansion_rules/link_expansion.rb
[link-graph]: ../app/models/link_graph.rb
[locale]: model.md#user-content-locale
