# Decision Record: Serving draft content using GraphQL

## Context

GOV.UK provides functionality for publishers to preview draft content. This content can be sensitive, e.g. it can reflect unannounced government policy or contain full transcripts of speeches yet to be delivered.

Currently, we maintain a separate instance of Content Store which contains only the draft content. We also have separate instances of the frontend applications, which only use the Draft Content Store. These applications sit behind Authenticating Proxy, to ensure only authorised users can access the content.

Draft content is visible in one of two ways:

- To users with a Signon account who have the 'signin' permission for 'Content Preview' (which is the name for the 'app' which allows access to the draft stack in Signon). This can be further restricted to only specific users or users from specific departments.
- To those who have an 'auth bypass ID', which is a query parameter that can be used to share previews of drafts with subject matter experts who do not have a Signon account.

Unlike Content Store, Publishing API maintains a single database containing both live and draft content. This means there are considerations that need to be made when serving draft content using GraphQL (which is part of Publishing API).

Since the GraphQL endpoint initially only served live content, no consideration for authentication or authorisation had been made thus far, since the content being served is already live to the public. The ability to retrieve draft content has [now been added](https://github.com/alphagov/publishing-api/pull/3908) and is currently behind a feature flag, so we now must consider how to serve this content correctly.

## Decision

### Requests for draft content will need to be authorised

Draft deployments of frontend applications will need to authenticate themselves to make requests for draft content, using a bearer token issued by Signon. This will be done using the `gds-sso` gem's `authenticate_user!` method. Once authenticated, the client (i.e. the draft deployments of the frontend applications) will also need to be authorised to make the query. This will be done by adding a permission to Signon for Publishing API, which only the draft deployments of the frontend applications will be granted. This will prevent live deployments of the frontend applications inadvertently making requests for draft content.

Requests for live content do not need to be authenticated and frontend applications will not need to be authorised to access this content, as the data being returned is considered publicly available content. This applies only to queries originating internally (i.e. from GOV.UK's own frontend applications). There is a separate piece of work ongoing which has a proposal to add authentication to all public API endpoints, which could include the GraphQL live content endpoint should we make the decision to open it to external users (such as the GOV.UK app).

### Request headers

Requests for draft content from clients may contain certain headers.

The headers are:

- `X-Govuk-Authenticated-User`: the user's ID
- `X-Govuk-Authenticated-User-Organisation`: the ID of the user's organisation
- `Govuk-Auth-Bypass-Id`: the auth bypass ID provided by the user in the request query string

These are the same headers currently used by Content Store.

### Access control logic will be ported to Publishing API

Content Store's [`can_view?`](https://github.com/alphagov/content-store/blob/d070c44368d11f8c578ac12c1c4ab82ccbe8bb3c/app/controllers/content_items_controller.rb#L20) method decides whether a user is permitted to view content. This logic will be introduced into Publishing API's controller methods that allow users to request draft content.

This method uses the headers that are provided in the request and the same will apply in Publishing API. These headers will be processed in the GraphQL controller of Publishing API prior to making the GraphQL query. The controller method for drafts already retrieves the full edition, which contains all the information required to determine whether a given request can view the edition. This means we will not require the computation of the GraphQL query if the user is not authenticated to view the content.

### Freeform GraphQL queries

Publishing API also has an endpoint which can accept freeform GraphQL queries. These queries can include a `with_drafts` parameter. This endpoint will therefore be subject to the same requirements as the draft content endpoint.

## Implementation plan

No draft deployments of frontend applications will be granted the permission to request draft content until we've implemented the entirety of the decision detailed above.

Bearer tokens will need to be issued in Signon for each draft deployment of frontend applications and the token added to the secrets manager. The client's API user in Signon should be given the draft permission for Publishing API.

To switch draft deployments of frontend applications to use the GraphQL endpoint, the request URL can be updated through the [`govuk_content_item_loader` gem](https://github.com/alphagov/govuk_content_item_loader).

## Consequences

The decisions in this ADR will mean draft content remains private and not publicly accessible, beyond the limited user scope who can already view it.

By maintaining feature parity with Content Store, draft deployments of frontend applications should barely notice the difference from using Content Store, other than the request URL and the token used to authenticate their request.
