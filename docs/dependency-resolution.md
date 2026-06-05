# Dependency Resolution

## Contents

- [Introduction](#introduction)
- [When it occurs](#when-it-occurs)
- [Determining editions to re-present](#determining-editions-to-re-present)
- [Updating Content Store](#updating-content-store)
  - [Content Store HTTP headers](#content-store-http-headers)
- [Debugging](#debugging)

## Introduction

Dependency resolution is a concept within the Publishing API to describe the
process of determining which editions require being re-presented to a
[Content Store][content-store] as a result of a change in another edition.

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
[DependencyResolutionJob][dependency-resolution-worker]. The dependency
resolution process itself is triggered as a result of different Sidekiq
workers ([DownstreamDraftJob][downstream-draft-worker],
[DownstreamLiveJob][downstream-live-worker], and
[DownstreamDiscardDraftJob][downstream-discard-draft-worker]) who are
responsible for updating the Content Stores any time an edition changes.

Thus any time an edition is updated and re-presented in the content store
the dependency resolution process will run and update items linked to the
document of the edition. This means that for a single edition update there
can be many requests to the Content Stores.

## Determining editions to re-present

When an edition of document, `A` has been updated all content that include a
link to `A` in their JSON links may need updating. The process of dependency
resolution determines the `content_id` of every item, and then re-presents
that item in each locale that is available.

For reference of the types of links see
[docs/link-expansion.md](link-expansion.md)

The class responsible for determining which `content_id`s require updates is
[DependencyResolution][dependency-resolution]. It uses the
[link expansion rules][link-expansion-rules] to perform the inverse process of
link expansion. It walks the links graph breadth-first (the reverse of
[link expansion](link-expansion.md#how-it-is-computed)) via
[`DependencyResolution::BreadthFirstResolver`][breadth-first-resolver],
collecting the `content_id` of every item whose expanded links include `A` —
both items that link to `A`, and items `A` links to via link types that have a
reverse name (for example a role appointment's `person` and `role` links) —
recursing through the recursive link paths a level at a time.

Unlike link expansion, dependency resolution works purely on the links graph: a
dependent `content_id` is returned whether or not it has a renderable edition,
so the resolver reads the `links` table directly rather than the
edition-joining batch SQL. Edition links only matter at the root; deeper levels
follow link set links only.

The [Queries::ContentDependencies][content-dependencies] class is responsible
for determining the locales of each `content_id`.

## Updating Content Store

As a result of the dependency resolution process, editions identified to
be presented will be queued in the Sidekiq workers:
[DownstreamDraftJob][downstream-draft-worker] and
[DownstreamLiveJob][downstream-live-worker]. These workers communicate
with the content store.

### Content Store HTTP headers

HTTP Requests to the Content Store contain HTTP headers that can be used
to determine the origin of the request:

- **Govuk-Request-Id** - An ID associated with the initial HTTP request which
  triggered the request to the Publishing API
- **Govuk-Dependency-Resolution-Source-Content-Id** - The `content_id` of the
  item that initiated dependency resolution, an empty value for this implies
  the request was not the result of dependency resolution.

## Debugging

You can explore dependency resolution in the rails console by creating a
[`DependencyResolution`][dependency-resolution] instance and listing the
dependent `content_id`s.

```
> DependencyResolution.new(content_id, locale: :en, with_drafts: true).dependencies
=> ["4ff219a8-f2e6-4fca-9b73-ebaebc9c7b6a", "..."]
```

To inspect the expanded tree of an item (rather than the flat dependency list),
use [link expansion](link-expansion.md#debugging-link-expansion):

```
> LinkExpansion.by_content_id(content_id, locale: :en, with_drafts: true).links_with_content
```

[content-store]: https://github.com/alphagov/content-store
[dependency-resolution]: ../lib/dependency_resolution.rb
[dependency-resolution-worker]: ../app/workers/dependency_resolution_worker.rb
[downstream-draft-worker]: ../app/workers/downstream_draft_worker.rb
[downstream-live-worker]: ../app/workers/downstream_live_worker.rb
[downstream-discard-draft-worker]: ../app/workers/downstream_discard_draft_worker.rb
[content-dependencies]: ../app/queries/content_dependencies.rb
[dependency-resolution]: ../lib/dependency_resolution.rb
[content-dependencies]: ../app/queries/content_dependencies.rb
[link-set-link]: link-expansion.md#patch-link-set---link-set-links
[link-expansion-rules]: ../lib/expansion_rules/link_expansion.rb
[edition-link]: link-expansion.md#put-content---edition-links
[breadth-first-resolver]: ../lib/dependency_resolution/breadth_first_resolver.rb
