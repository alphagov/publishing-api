# Decision Record: Cache Rendered Govspeak

## Context

[Govspeak](https://github.com/alphagov/govspeak) is GOV.UK’s extension to markdown. In Publishing API, Govspeak is parsed and rendered to HTML at the point of presentation to Content Store, in the [DetailsPresenter](https://github.com/alphagov/publishing-api/blob/804ea33f399b1b2da75869810be480e5cc2a1e9b/app/presenters/details_presenter.rb#L16).

As this occurs at the point of putting draft content or publishing content, the performance is less important.

In the [work on GraphQL](https://github.com/alphagov/govuk-rfcs/blob/6b1379652139e3fac405c4d751ca21bc4cc846cc/rfc-172-graphql-for-govuk.md), we have moved the parsing and rendering of Govspeak to the point of the content being requested by a consumer (i.e. frontend application). The performance of this rendering now becomes important.

For large amounts of content, we see this process as being a bottleneck in the presentation of content to the consumer.

## Decision

A decision has been made to continue pre-computing rendered Govspeak at the point of putting draft content or publishing. However, to support GraphQL (which does not use Content Store), we will now need to cache the rendered Govspeak in Publishing API’s database.

This will involve moving the `recursively_transform_govspeak` method out of the `DetailsPresenter` and into the `PutContent` command. Once the govspeak has been transformed, we will need to insert the parsed govspeak into the relevant part of the `details` hash.

In addition to this, we should store some metadata (e.g. that this was rendered by Publishing API and the version of govspeak used). This will allow us to identify which data was provided by the publishing application and which was produced by Publishing API.

An example of how this data could be represented in the `details` field for an edition:

```
{
  "body": [
    { "content_type": "text/govspeak", "content": "..." },
    {
      "content_type": "text/html",
      "content": "...",
      "govspeak_version": "10.6.5"
      "rendered_by": "publishing_api",
    },
  ],
  "other_fields": {...}
}
```

The `DetailsPresenter` would then need to be updated to use the cached version of the content, instead of computing it again.

We could have a background process that identifies when a new version of govspeak has been released. When that occurs, we will re-compute all the details for all editions (using the govspeak version stored in the metadata to identify those editions that need updating). However this is not a strict requirement, as we already need to manually re-render content in Content Store when govspeak is updated.

There will be no changes to the processing of embedded content blocks. These will continue to be rendered in the `DetailsPresenter` (i.e. at the point of rendering for GraphQL or at the point of sending the content to Content Store).

## Consequences

This will speed up the rendering of content when using GraphQL.

The deployment of this change will need to occur in multiple steps:

1. Add the `recursively_transform_govspeak` code to the `PutContent` command, then store the output in the database.
1. Run a one-off task to pre-compute and store the Govspeak for all existing editions. It would be reasonable to limit this to only draft and live editions, ignoring those that are superseded.
1. Switch the `DetailsPresenter` to use the pre-computed cached version of the content.

There is a trade off between these performance enhancements and the benefit of rendering Govspeak at the point of users making a request. Without rewriting Govspeak, there is little opportunity to make any other performance improvements. This means Govspeak will still need to be re-rendered on all documents when any changes are made to how Govspeak renders elements. However we can remove the manual toil that currently exists, by having a background process that automatically re-computes cached govspeak when a new version of govspeak is released.

If we find storing the rendered version of govspeak inflates the size of the `editions` table too much, we could remove the rendered version at the point of an edition being superseded.

PutContent API responses may get slower, as we're now rendering govspeak synchronously where previously it happened in a queue job.

## Alternatives considered

### Store the rendered content in another column

This would involve adding an additional JSONB column to the `editions` database table to cache the rendered content, however would result in considerable duplication of data.

### Store the rendered content in a separate table

Whilst this would prevent a size increase of the editions table, the new table would need a key consisting of at least the `content_id`, `locale` and `content_store`, which could create additional performance overheads when joining this to the editions table.

### Caching at the point of first request

This would involve computing the govspeak at the point an edition is first requested after it has been published, rather than at the point of publication. Poor performance would be seen the first time a edition is requested, which could negatively impact response times.
