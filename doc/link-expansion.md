# Link Expansion

## Contents

- [Introduction](#introduction)
- [Example output](#example-output)
- [When it occurs](#when-it-occurs)
- [Link sources](#link-sources)
  - [Links added via `patch-link-set` (dependees)](#links-added-via-patch-link-set-dependees)
  - [Links added automatically](#links-added-automatically)
    - [Reverse links (dependents)](#reverse-links-dependents)
    - [Available translations](#available-translations)
  - [Recursive links](#recursive-links)
    - [Recursive link paths](#recursive-link-paths)
- [Link presentation](#link-presentation)
  - [Fields](#fields)

## Introduction

Link expansion is a concept in the Publishing API which describes the process
of converting the stored links of a content item into a JSON representation
containing the details of these links. It is used in the Publishing API
during the process of sending a content item downstream to the
[Content Store][content-store].

The process involves determining which content items should and can be linked
to, the versions of them that are linked, and the fields that will be included
in the representation. It replaces a process in the Content Store which was
used to determine and expand links at the point of request.

A closely related process to this is
[dependency-resolution](dependency-resolution.md). This is something of a
reversal in link expansion and has the role of determining which content items
will need re-presenting to the content store as a result of an update to a
content item.

## Example Output

Below is an abridged example of a content item represented as JSON after link
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
      "schema_name": "placeholder",
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
      "schema_name": "placeholder_corporate_information_page",
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
      "schema_name": "placeholder_corporate_information_page",
      "title": "Cynllun iaith Gymraeg",
      "links": {}
    }]
  },
}
```

Within a `links` JSON object there are keys which indicate which a type of link,
and at the value of those keys is an array of all links of that type. In the
above example there are two types of link: `organisations` and
`available_translations` which contain 1 and 2 links respectively.

## When it occurs

Link expansion occurs at the point a content item is represented to the
Content Store - which is normally the result of a [Sidekiq](http://sidekiq.org/)
worker process such as [DownstreamDraftWorker][downstream-draft-worker] or
[DownstreamLiveWorker][downstream-live-worker].

## Link sources

The links for a content item are a combination of links which are added
via [`patch-link-set`](api.md#patch-v2linkscontent_id) and those that are
determined automatically.

### Links added via `patch-link-set` (dependees)

Links added via `patch-link-set` are stored for a content item as a
collection of content ids, all with a link type and ordering index. These are
always presented as part of link expansion, and some of the link types provided
here may also include the links for the linked item if they are of a
[recursive link type](#recursive-links).

These are considered to be **depenees** of a content item and are determined
using the [`Presenters::Queries::ExpandDependees`][expand-dependees] class.

### Links added automatically

There are two types of links which are added automatically as part of link
expansion, these are reverse links and available translations.

#### Reverse links (dependents)

Some types of links are presented when they are the target of a link.

Consider item `A` which links to item `B` - with type `reciprocal` - and `B` does
not have a link to `A`. Under normal circumstances this will mean that the
links for `A` would include `B`, yet `B` would not include `A` in it's
links. However if `reciprocal` is defined as a reverse link it will also be
included in the links for `B`, under a link type of the defined reverse name
for "reciprocal". These are defined in
[`Queries::DependentExpansionRules`][dependent-expansion-rules].

An example of a reverse link type is `parent` which is defined as having a
reverse name of `children`. Consider item `C` which has a link to
item `D` with type `parent`. In `C` you would have a group of `parents`
links which includes `D`, whereas in `D` you would have a group of
`children` links which includes `C`.

Reverse links are considered to be **dependents** of a content item and are
determined using the [`Presenters::Queries::ExpandDependents`][expand-dependents]
class.

#### Available translations

A content item can be available in multiple translations. This will be
determined by content items sharing the same [`content_id`][content-id] and
having different [`locale`][locale] values.

The links for a content item will include all the translations of a content
item, including the current locale.

**Example**

For item `E` which exists in English ("en") and Welsh ("cy") the available
translations links include a link to the "en" and "cy" variations of the
content item.

### Recursive links

Some link types are considered recursive which is used to present a tree
structure of links of specific types. As with many things recursive, these
link types are frequently a source of confusion.

These are used in cases where it is beneficial to know the links of a content
item when linking to that item.

A common use case for this is breadcrumbs, where we may want to know the
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
subsequent parent forming a tree of:

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

The last item in a path of link types is considered **_sticky_**. This means that
there can be many items of this type in the path. There can only be instance of
items before the _sticky_ type, and there is no limit to the amount of items that
can be of the _sticky_ type.

For the path `ordered_related_items`, `mainstream_browse_pages` and `parent`
there can therefore be any number of `parent` items, and only 1 instance of
`ordered_related_items` and `mainstream_browse_pages`.

This is a valid path for `ordered_related_items`, `mainstream_browse_pages` and `parent`:

```
"Item A" -ordered_related_items-> "Item B" -mainstream_browse_pages-> "Item C" -parent-> "Item D" -parent-> "Item E" -parent-> "Item F"
```

Yet this is invalid:

```
"Item A" -ordered_related_items-> "Item B" -mainstream_browse_pages-> "Item C" -mainstream_browse_pages-> "Item D" -parent-> "Item E" -parent-> "Item F"
```

The rules for recursive link types are defined in
[`Queries::DependentExpansionRules`][dependent-expansion-rules].

## Which states are linked

Whether an item is linked to is dependant on whether the content item being
linked to exists in a particular [state](model.md#state). The states that are
applicable are determined by the state of the content item that link expansion
is performed for.

### Content item has a state of `published` or `unpublished`

Reverse links are included if a content item exists for them in a `published`
state.

All other link types are included when a content exists in either a `published`
state or a `unpublished` state with a type of `withdrawn`.

### Content item has a state of `draft`

Content items follow the same rules as those for `published` or `unpublished`
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
- `content_id` - A UUID to represents the content item
- `description` - A short description of the content item
- `document_type` - The document of the content item
- `locale` - The language the content item linked to is in
- `public_updated_at` - The date/time that a content item was last changed
- `schema_name` - The [GOV.UK content schema][govuk-content-schema] that a
  content item conforms to
- `title` - The title of a content item
- `links` - Any [recursive links](#recursive-links) that are presented with a
  link representation of a content item

The fields can and are customised in some cases. This can be done on a
`link_type` basis. These customisations can be performed in
[`Presenters::Queries::ExpandDependees`][expand-dependees] and
[`Presenters::Queries::ExpandDependents`][expand-dependents] - where the latter
is for [reverse links](#reverse-links).

[content-store]: https://github.com/alphagov/content-store
[downstream-draft-worker]: ../app/workers/downstream_draft_worker.rb
[downstream-live-worker]: ../app/workers/downstream_live_worker.rb
[expand-dependees]: ../app/presenters/queries/expand_dependees.rb
[expand-dependents]: ../app/presenters/queries/expand_dependents.rb
[dependent-expansion-rules]: ../app/queries/dependent_expansion_rules.rb
[content-id]: model.md#user-content-content_id
[locale]: model.md#user-content-locale
[apprenticeship-standards]: https://www.gov.uk/government/collections/apprenticeship-standards
