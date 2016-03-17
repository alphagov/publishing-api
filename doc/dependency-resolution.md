## Dependency Resolution

**Problem Statement**

We're undergoing a migration to the new publishing platform. The publishing
platform doesn't currently prescribe how the following features should work:

- Breadcrumbs

These are links that appear at the top of the majority of GOV.UK pages and allow
users to navigate up to a higher-level page

- Related Links

These are links that appear on the right hand side of the majority of GOV.UK
pages and allow users to navigate to content that is related to the content they
are currently viewing. When two pages are related, this relationship tends to
be bidirectional.

- Support for Govspeak

Many of our publishing applications support a language called Govspeak, which is
used for adding formatting structure to content, such as headers, lists and
links. It is possible in Govspeak to add a link to another piece of content,
which could be changed independently.

- Collections of content

There are a few pages on GOV.UK which are collections of other content. These
pages are effectively directories of links to other content. Each of these links
can change independently and its title should be updated on the collection page.

- Centralised search indexing

Currently, publishing applications manually speak to Rummager which indexes
their content for search. We'd like to centralise this behaviour so that the
Publishing API forwards this content to Rummager in its expanded form for
search indexing.

Note: In addition to these requirements, there are some non-functional
requirements detailed below. This includes a architectural goal of moving
towards a simpler content store that could be replaced with a simple storage
technology rather than an application that must be maintained.

**Summary**

In all of these cases, there is a dependency between content items. In the first
case, the name of a page might change or the hierarchy might change. This would
mean that we have to update the breadcrumbs for many pages to reflect this.

In the second case, the title or path of a related link could change which would
require an update to any content item that linked to the changed item. This is
very similar in the third and fourth cases where embedded links would need to be
updated to reflect the new title / path of the content.

**High-Level Approach**

The agreed, high-level approach to cope with these scenarios is to have the
Publishing API track and resolve dependencies on behalf of publishing
applications. This is notionally a difficult thing to achieve and we'd rather
solve this problem once as part of the platform than over and again in various
publishing applications.

We already capture some information about the dependencies of content items in
their 'links' data. We intend to extend this behaviour to incorporate new
business logic that will check these dependencies when content changes,
determine which things need to be updated and send these content items
downstream to the content store automatically.

Until now, we haven't got much further than this in detailing how this solution
will work. This write-up details the analysis of this problem and presents a
solution that aims to meet business requirements.

**Non-Functional Requirements**

In addition to the functional requirements for the features described in the
Problem Statement, there are additional non-functional requirements that we
should bear in mind when considering a proposal.

- Publishing API response times

We need to ensure that response times to the Publishing API are kept within
reasonable boundaries to ensure that we don't introduce problems with publishing
applications timing out.

- Network communications

We should consider the number of communications between the Publishing API and
the Content Store. It is anticipated that in some cases, a large number of items
could be dependent on specific items. An example of this is the Home page, which
is likely to appear in the breadcrumbs for a lot of pages. If we were to update
the Home page, we should be careful not to unnecessarily send tens of thousands
of updates unless this is absolutely necessary.

- Choice in technology

We should be careful about the choice in technology to solve this problem.
Ideally, we should choose technology that is familiar and well-understood by the
majority of people. If we do decide to introduce new technology, e.g. a graph
library, then we should ensure it is worth the added overhead of having to learn
the ins and outs of something new.

- Simpler, dumber Content Store

We'd like to move to a simpler architecture where the content store does very
little and simply houses content. Ideally, it could be swapped out for an S3
bucket. This would mean we wouldn't have to maintain an additional application,
reducing support and maintenance overheads.

- Re-use

We currently support some links-related features in Publishing API. We have an
endpoint for retrieving which content items link to a given content item, for
example. It is likely that we will want to make use of this dependency
resolution feature for other things. We should therefore consider how re-usable
the approach is for other users of the Publishing API with their own set of
requirements.

**Problem Analysis**

There are a number of distinct parts of the problem to consider.

- Tracking dependencies

We need to consider how dependencies will be tracked. Currently, you can
specify the 'links' for a content item, to directly associate a single content
item with potentially many other content items. These links can be grouped up
arbitrarily depending on what they are to be used for. At present, these links
only contain the content_ids of other items. We then "expand" these links when
front-end applications make requests to the content store.

Currently, there is no way to specify that a content item depends on specific
fields of another content item. For the breadcrumbs requirement, this is
important because we only depend on the title and base path in this case. If we
were to use the 'links' hash to track parenthood, we'd also need some mechanism
to scope it to those fields. If we didn't do this, we'd risk unnecessarily
sending updates, which is something we're keen to avoid.

Currently, dependencies can't be tracked at a level further than one content
item away. Again, for the breadcrumbs, we'd need to track dependencies for the
whole ancestry and not just the immediate parent. There are other cases where
we should not follow dependencies recursively and should only consider the
nearest neighbour. An example of this is related links.

In order to satisfy the requirement for collections of content, we'd need to
track dependencies in either direction to form a parent-child relationship. In
this case, each of the children would require a breadcrumb to navigate up to the
collection and the collection would need to know all of its children for their
links to be rendered on the collection page.

The links for a content item are pushed into our system via a single endpoint
that applies to both draft and published content. This means that we don't need
to track dependencies separately for content in different states.

- Detecting when dependencies change

Dependencies can change as a result of a various interactions with the
Publishing API. When someone updates content, we should check to see if any
other items depend on that item and if so, whether they specifically depend on
the fields that have changed.

The Publishing API currently sends content into two distinct content stores. One
of these is for draft content and the other is for published content and is
presented to users of GOV.UK. Although the dependencies can be tracked
separately, this is not true for the detection of changes. We'd need to detect
draft changes and published content changes separately because the workflow
of content is richer than that of links.

Another interaction that can change dependencies is when the links themselves
change. For example, the parenthood of a content item might change which would
in turn affect the breadcrumbs of its children. As mentioned above, the workflow
is simpler for links and this means that we can detect changes for draft and
published content at the same time when the links change.

- Re-sending the content

When sending content to the content store, we must first prepare that content by
presenting a payload. Although this doesn't take long, when applied to a large
number of items, the time taken could become significant. In addition to this,
the detection of dependencies could be time consuming and we should be careful
to keep these operations outside of the publishing application's request cycle
where possible.

**Technical Proposal**

This technical proposal puts forward a moderately detailed plan for how to meet
business requirements with consideration to the Problem Analysis.

- Tracking dependencies

To track dependencies, we can make use of the existing 'links' feature for
specifying dependencies between content items. For example, if content item A
has a parent of B, we should track this by adding B into A's links in the
'parent' group. For the most part, we already do this.

To specify the fields that a content item depends on, we should do so in the
content schemas. This set of fields varies by use case, which relates to the
name of the group. For example, the 'parent' group requires a 'title' and a
'base_path' and so it is proposed to capture this data on a group basis to apply
generally across all formats. If required, we can add a finer level of control
over this in the future – perhaps to specialise it on a group/format basis.

Additionally, the recursive behaviour for dependency tracking should be captured
in the schemas. We'd capture that the 'parent' group should recurse in order to
track the full ancestry of content items as its dependencies. This differs for
the 'related' group, which would not need to recurse. Therefore, I propose that
we have a simple boolean value that represents whether to recurse or not. Again,
we can add a finer level of control for this later if required.

Finally, we should specify the default behaviour when custom configuration is
not specified. This should also go into the schemas and exactly match the way in
which link expansion works currently. i.e. it should not recurse and it should
contain the set of fields that are currently expanded (title, base_path, etc).

Note: Bidirectional dependencies is documented separately later on.

- Detecting when dependencies change

The Publishing API can receive interactions that affect dependencies. When we
receive one of these interactions for a given content_id, we should explicitly
check its dependencies and send updates downstream. Because the rules for how
dependencies are tracked is captured in the content schemas, it is proposed that
Publishing API be granted visibility over the content schemas in production so
that it can apply these rules when detecting changes. We had already planned to
do this for the purpose of validating content against the schemas in the
Publishing API.

Once it has visibility over the dependency rules for each of the groups, it
should run a query against the database to detect content items that need to be
updated as a result of the incoming request. It will do this using Postgres's
WITH RECURSIVE functionality. This was explored in the following branch to
demonstrate that it is feasible to detect dependent nodes in this way:

[https://github.com/alphagov/publishing-api/tree/dependency-transitive-closure](https://github.com/alphagov/publishing-api/tree/dependency-transitive-closure)

We should make it so that this query only follows edges in the dependency graph
for groups which contain any of the fields that have changed on the content
item. We can determine which fields have changed using Rails's
[ActiveModel::Dirty](http://api.rubyonrails.org/classes/ActiveModel/Dirty.html)
methods. The branch linked to above demonstrates that it is possible to restrict
edges followed by a link_type (which is another name for 'group'). The recursive
behaviour of this query depends on the boolean configuration setting for that
group and should be factored into the query.

All of this behaviour should be completed out-of-band from the publishing
application's request cycle with the Publishing API. It is proposed that we
isolate all of this dependency resolution work into a separate Sidekiq worker
that is responsible for determining the set of content items that need to be
updated and for actually presenting and sending those updates downstream. When
the Publishing API receives any interaction that can affect dependencies, it
need only place this content item on a 'dirty' queue for processing by the
dependency resolution worker.

If required, we can separate the calculation of dependencies from sending the
updates downstream into separate workers/queues. The important thing is that
both of those tasks happen out-of-band to the request cycle.

Note: Bidirectional dependencies is documented separately later on.

- Link expansion

It is proposed that we move link expansion into the publishing api and send the
fully-pressed content item downstream to the content store. For each of the link
groups that appear on the content item, it will need to look up the rules for
those groups from the schemas and expand those fields from the dependent content
items.

We also need to consider a new data structure to represent recursively expanded
links. It is proposed that the structure remain almost identical with the key
difference that the links for dependent content items are recursively expanded
in the links data. For now, I think we should include the expanded links as a
separate field in the content item. Perhaps this can be called "expanded_links",
or similar and we can send it alongside the unexpanded links. As we migrate
applications to use dependency resolution, we should make them use this field
instead of "links" and look at retiring the expansion of links in content store.

**Bidirectional Dependencies**

As mentioned, we have a requirement for bidirectional dependencies, in the case
of the collections requirement. Perhaps the simplest way to satisfy this
requirement is to manually add a separate group for 'children' that mirrors that
of the 'parent' group. However, this would place a burden on publishing
applications to manage this for themselves and it could be problematic if these
groups fall out of sync.

Therefore, this proposal recommends that bidirectional dependencies be handled
explicitly as an additional feature of dependency resolution. I propose we add
some additional configuration settings in the content schemas. There will be an
option to state that a particular dependency is the reverse of something else.
For example, the 'children' group would be marked as the reverse of the 'parent'
group.

It is important to note that, although these groups are related, they could
differ in their expansion fields, as well as the recursive nature of their
expansion. To use the parent / child example, again – a child's parent will form
part of its breadcrumbs and so its full ancestry would need to be expanded in
order to render these. A group's children, however, could be presented one level
at a time and need not be expanded recursively to form the full hierarchy of
descendents.

In cases where a group has been marked as the reverse of something else, the
publishing application need only provide the content ids for the original group
and not the reverse. When the Publishing API detects which content items need to
change, it can use the same WITH RECURSIVE query, but instead travel in the
other direction, following edges forwards through the dependency graph.

The presentation of the links would also need to consider reverse dependencies
prior to them being sent downstream to the content store. This can work in a
similar manner and as far as the presentation is concerned, the data structure
that we already have (albeit with provisions for recursion) is sufficient to
acommodate these additional groups.

**Exposure via an Endpoint**

We might also consider exposing dependency resolution queries via an endpoint
on the Publishing API. We currently support simple cases of this in the form
of /links and /linked and it might make sense to collapse these into a single
endpoint that leverages the dependency resolution queries to be implemented as
part of this proposal.
