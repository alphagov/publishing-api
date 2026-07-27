# Decision Record: Batch link expansion and dependency resolution at publish time

## Context

Publishing API currently has two implementations of link expansion:

1. At publish time, lib/link_expansion.rb traverses the link graph recursively in depth-first order
2. When handling GraphQL requests, the classes in app/graphql/sources/* traverse the link graph using dataloaders in
   breadth-first order

Both produce the same output (verified by integration tests in `spec/integration/graphql/link_expansion/`).

The approach in the GraphQL code is much more efficient however, because it makes far fewer SQL queries. It batches up
the nodes at each level of depth, so it makes **O(depth)** queries instead of **O(nodes)** queries.

The code for both implementations is complex, but in different ways.

The publish-time code is hard to follow because of the interplay between `LinkGraph`, `Node` and `NodeCollectionFactory`
as well as the optimizations in `Queries::Link` (particularly around `has_own_links` and `is_linked_to`, which are used
to avoid making queries which won't return any results).

The code in the GraphQL implementation on the other hand is hard to follow because it depends on two ~100 line SQL
queries.

Any updates made to either approach risk causing inconsistencies between them, which can be difficult to debug.

## Decision

We will update the publish time link expansion code to use the breadth-first, batched approach currently used by the
GraphQL dataloaders.

We will also refactor dependency resolution to use a similar batched algorithm.

We will remove the `LinkGraph` / `Node` / `NodeCollectionFactory` classes, along with `LinkExpansion::ContentCache`
and the `LinkReference` classes. `Queries::Links` and `Queries::EditionLinks` will remain in use at the root of
dependency resolution, but `Queries::Links` can be simplified, as its `has_own_links` optimizations won't be needed
anymore.

These changes will aim to be a pure refactoring - there should be no observable change to the outputs of link expansion
at all, but publish-time performance should improve dramatically.

### Important edge cases

There are a couple of quirks of link expansion that need to be considered.

#### Edition links are only followed at root level

The publish-time link expansion code only looks for edition links at the root level, whereas the GraphQL code permits
them at any level.

The publish-time code also treats edition links as leaf nodes - it doesn't recursively expand the links of editions
found through edition links.

The GraphQL code looks for edition links at all levels, and expands their children recursively.

To keep this as a pure refactoring, we'll need to preserve the existing publish-time behaviour with respect to edition
links.

#### Cycle prevention

The publish-time link expansion code prevents cycles by checking that any content_ids don't appear in their ancestors.

The GraphQL code doesn't address this, instead relying on depth limits in the GraphQL queries to prevent infinite loops.

We will need to retain cycle prevention to avoid infinite loops.

#### Auto-reverse link behaviour

When the root edition has a reverse link at level 1 (e.g. `children` or `child_taxons`), link expansion automatically
adds a link back to the root edition in the other direction. So instead of `root -> children` we get
`root -> children -> parent`, or instead of `root -> child_taxons` we get `root -> child_taxons -> parent_taxons`.

These link paths are removed when following the link expansion rules, as they're cycles, but auto-reverse linking
happens separately as a post-processing step and adds them back.

This behaviour is probably useful in the many-to-one examples (like parent / children). It's confusing for other reverse
link types where the relationship is many-to-many though. For example if the root is a `document`, we get an
auto-reverse link through `document -> document_collections -> document`. This seems to imply that the root node is the
only document in the document_collection, but it usually isn't.

Regardless, as we're aiming for a pure refactor we'll need to preserve the auto-reverse link behaviour. This can remain
as a post-processing step, after the graph traversal.

### Implementation plan

1. Double check test coverage, and add any missing tests 
2. Move the SQL files from the GraphQL directory into `app/queries/sql`, extracting the GraphQL sources that read
   them into shared `Queries` classes
3. Create new implementations of link expansion and dependency resolution (but don't use them yet)
4. Test that the new implementation matches the old implementation exactly, and confirm the impact on performance 
5. Switch to the new implementation
6. Remove the old implementation and clean up any unused code
7. Update the documentation

## Consequences

1. Better performance due to fewer database queries per expansion
2. Simpler code (removing `LinkGraph` and associated classes)
3. Single source of truth for link queries, preventing accidental divergence
4. Making it easier to support nested edition links in future
