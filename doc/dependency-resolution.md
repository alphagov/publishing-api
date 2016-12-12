# Dependency Resolution

## Contents

- [Introduction](#introduction)
- [When it occurs](#when-it-occurs)
- [Determining content items to re-present](#determining-content-items-to-re-present)
  - [Linked to a content item](#linked-to-a-content-item)
    - [Recursive links](#recursive-links)
  - [Reverse links](#reverse-links)
  - [Translations](#translations)
- [Updating Content Store](#updating-content-store)
  - [Content Store HTTP headers](#content-store-http-headers)

## Introduction

Dependency resolution is a concept within the Publishing API to describe the
process of determining which content items require being re-presented to a
[Content Store][content-store] as a result of a change to a content item.

The Content Stores contain static JSON representations of content items. There
are links between content items and the details of these links are stored in
this JSON representation. The process for determining and presenting these
links is called [link expansion](link-expansion.md). Any time a content
item changes there could be many different content items that require
re-presenting. Dependency resolution is the process to determine which items
require this.

## When it occurs

Dependency resolution occurs in a background process provided by a
[Sidekiq](https://sidekiq.org) worker:
[DependencyResolutionWorker][dependency-resolution-worker]. The dependency
resolution process itself is triggered as a result of different Sidekiq
workers ([DownstreamDraftWorker][downstream-draft-worker],
[DownstreamLiveWorker][downstream-live-worker], and
[DownstreamDiscardDraftWorker][downstream-discard-draft-worker]) who are
responsible for updating the Content Stores any time a content item changes.

Thus any time a content item is updated and re-presented in the content store
the dependency resolution process will run and update items linked to the
original content item. This means that for a single content item update there
can be many requests to the Content Stores.

## Determining content items to re-present

When a content item, `A` has been updated all content items that include a
link to `A` in their JSON links may need updating. The
[Queries::ContentDependencies][content-dependencies] class is responsible for
determining all of these. The types of link can be broadly split into 3
categories: linked to a content item, reverse links, and translations.

### Linked to a content item

The most simple type of link to a content item is an explicit one where for a
content item `B` there is a link that targets a content item `C`. When
dependency resolution occurs as the result of a change to `C` items that link
to it, such as `B`, can be looked up simply.

#### Recursive links

Some link types are considered [recursive](link-expansion.md#recursive-links),
for these a recursive process is used to determine which links should be
re-presented as a result of dependency resolution.

The [Queries::LinkedTo][queries-linked-to] class is used to determine the
`content_id` value of content items to re-present.

### Reverse links

There is a concept of [reverse links](link-expansion.md#reverse-links) where
links are automatically added as part of a content item presentation.

These are determined by the [Queries::ContentDependencies][content-dependencies]
class.

### Translations

If the content item that initiated dependency resolution is available in
multiple locales each of these will be re-presented to the content store.

Content items identified by links and reverse links will be updated in each
locale they are stored in.

## Updating Content Store

As a result of the dependency resolution process, content items identified to
be presented will be queued in the Sidekiq workers:
[DownstreamDraftWorker][downstream-draft-worker] and
[DownstreamLiveWorker][downstream-live-worker]. These workers communicate
with the content store.

### Content Store HTTP headers

HTTP Requests to the Content Store contain HTTP headers that can be used
to determine the origin of the request:

- **Govuk-Request-Id** - An ID associated with the initial HTTP request which
  triggered the request to the Publishing API
- **Govuk-Dependency-Resolution-Source-Content-Id** - The `content_id` of the
  item that initiated dependency resolution, an empty value for this implies
  the request was not the result of dependency resolution.

[content-store]: https://github.com/alphagov/content-store
[dependency-resolution-worker]: ../app/workers/dependency_resolution_worker.rb
[downstream-draft-worker]: ../app/workers/downstream_draft_worker.rb
[downstream-live-worker]: ../app/workers/downstream_live_worker.rb
[downstream-discard-draft-worker]: ../app/workers/downstream_discard_draft_worker.rb
[content-dependencies]: ../app/queries/content_dependencies.rb
[queries-linked-to]: ../app/queries/linked_to.rb
[content-dependencies]: ../app/queries/content_dependencies.rb
