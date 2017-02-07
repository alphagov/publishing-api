# Dependency Resolution

## Contents

- [Introduction](#introduction)
- [When it occurs](#when-it-occurs)
- [Determining editions to re-present](#determining-editions-to-re-present)
  - [Linked to a document](#linked-to-a-document)
    - [Recursive links](#recursive-links)
  - [Reverse links](#reverse-links)
  - [Translations](#translations)
- [Updating Content Store](#updating-content-store)
  - [Content Store HTTP headers](#content-store-http-headers)

## Introduction

Dependency resolution is a concept within the Publishing API to describe the
process of determining which editions require being re-presented to a
[Content Store][content-store] as a result of a change to an edition.

The Content Stores contain static JSON representations of document editions.
There are links between content and the details of these links are stored in
this JSON representation. The process for determining and presenting these
links is called [link expansion](link-expansion.md). Any time an edition
changes there could be many different editions that require
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
responsible for updating the Content Stores any time an edition changes.

Thus any time an edition is updated and re-presented in the content store
the dependency resolution process will run and update items linked to the
document of the edition. This means that for a single edition update there
can be many requests to the Content Stores.

## Determining editions to re-present

When an edition of document, `A` has been updated all content that include a
link to `A` in their JSON links may need updating. The
[Queries::ContentDependencies][content-dependencies] class is responsible for
determining the editions of documents that require re-presenting. The types of
link can be broadly split into 3 categories: linked to a document, reverse
links, and translations.

### Linked to a document

The most simple type of link is an explicit one where for a document `B` there
is a link that targets a content item `C`. When
dependency resolution occurs as the result of a change to `C` items that link
to it, such as `B`, can be looked up simply.

#### Recursive links

Some link types are considered [recursive](link-expansion.md#recursive-links),
for these a recursive process is used to determine which links should be
re-presented as a result of dependency resolution.

The [DependencyResolution][dependency-resolution] class is used to determine the
`content_id` value of documents whose editions need to be re-presented.

### Reverse links

There is a concept of [reverse links](link-expansion.md#reverse-links) where
links are automatically added as part of an edition presentation.

These are determined by the [Queries::ContentDependencies][content-dependencies]
class.

### Translations

If the edition that initiated dependency resolution is available in
multiple locales each of these will be re-presented to the content store.

Editions identified by links and reverse links will be updated in each
locale they are stored in.

## Updating Content Store

As a result of the dependency resolution process, editions identified to
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
[dependency-resolution]: ../app/lib/dependency-resolution.rb
[content-dependencies]: ../app/queries/content_dependencies.rb
