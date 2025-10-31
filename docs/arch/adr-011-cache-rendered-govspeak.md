# Decision Record: Cache Rendered Govspeak

## Context

[Govspeak](https://github.com/alphagov/govspeak) is GOV.UK’s extension to markdown. In Publishing API, Govspeak is parsed and rendered to HTML at the point of presentation to Content Store, in the [DetailsPresenter](https://github.com/alphagov/publishing-api/blob/804ea33f399b1b2da75869810be480e5cc2a1e9b/app/presenters/details_presenter.rb#L16).

As this occurs at the point of putting draft content or publishing content, the performance is less important.

In the [work on GraphQL](https://github.com/alphagov/govuk-rfcs/blob/6b1379652139e3fac405c4d751ca21bc4cc846cc/rfc-172-graphql-for-govuk.md), we have moved the parsing and rendering of Govspeak to the point of the content being requested by a consumer (i.e. frontend application). The performance of this rendering now becomes important.

For large amounts of content, we see this process as being a bottleneck in the presentation of content to the consumer.

## Decision

A decision has been made to continue pre-computing rendered Govspeak at the point of putting draft content or publishing. However, to support GraphQL (which does not use Content Store), we will now need to cache the rendered Govspeak in Publishing API’s database.

This will involve adding an additional JSONB column to the `editions` database table to cache the rendered content, then moving the `recursively_transform_govspeak` method out of the `DetailsPresenter` and into both the `PutContent` and `Publish` commands. The `DetailsPresenter` would then need to be updated to use the cached version of the content, instead of computing it again.

## Consequences

This will speed up the rendering of content when using GraphQL.

The deployment of this change will need to occur in multiple steps:

1. Deploy a schema migration to add the new column to the `editions` table.
1. Add the `recursively_transform_govspeak` code to the `PutContent` and `Publish` commands, then store the output in the new database column.
1. Run a one-off task to pre-compute and store the Govspeak for all existing editions. It would be reasonable to limit this to only draft and live editions, ignoring those that are superseded.
1. Switch the `DetailsPresenter` to use the pre-computed cached version of the content.

There is a trade off between these performance enhancements and the benefit of rendering Govspeak at the point of users making a request. Without rewriting Govspeak, there is little opportunity to make any other performance improvements. This means Govspeak will need to be re-rendered on all documents when any changes are made to how Govspeak renders elements. However there is little difference to the current state where the contents of Content Store need to be re-rendered when Govspeak is updated.
