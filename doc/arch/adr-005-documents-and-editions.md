# Decision Record: Resolve consistency and uniqueness in content

## Context

Publishing API has adopted the open/closed principle where the domain model is
based around a central ContentItem model, where there are numerous entities
that store data related to the ContentItem - however the ContentItem does not
have knowledge about them.

Over time this data structure revealed a number of problems to developers
and users of the Publishing API. Such as:

* Difficulty in maintaining uniqueness constraints, as these were in multiple
  tables - particularly problematic with concurrent requests.
* Long verbose queries that were inconsistent with how queries are normally
  authored in Ruby-on-Rails.
* Slow performing queries due to the need for many joins.
* Large amounts of code to try resolve problems identified.

A number of non-exclusive options were considered on how to resolve the issues:

* **Option 1**: Merge user_facing_version and locale into ContentItem table, as
  this would allow us to set a single uniqueness constraint that could raise an
  error on a concurrent request;
* **Option 2**: Merge user_facing_version, locale, base_path, and state into
  ContentItem table, as this would allow multiple uniqueness constraints but
  breaks from open/closed principal;
* **Option 3**: Split ContentItems into Document and Edition models, with
  Edition being a particular version of a Content Item and a Document spanning
  all versions;
* **Option 4**: Split a ContentItem model into two separate models, one that
  focuses on the uniqueness and relationships, the latter on the content;
* **Option 5**: ContentStore specified directly in the database rather than as a
  byproduct of the state value;
* **Option 6**: Store state history, this would change state from being a single
  field that is updated to a collection that is stored for a ContentItem;
* **Option 7**: Take a location centric approach to storing how base_path values are
  stored for ContentItems. This would involve a table storing which items use a
  particular base_paths and would open the door to storing other items (such as
  redirects) that require a base_path.

## Decisions

Each of the options was considered and a selection of them were chosen to be
implemented:

### Option 1

This was rejected in favour of Option 2 which effectively superseded it.

### Option 2

This was accepted as it was felt the additional complexity introduced by using
the open/closed principal was a greater cost to us than the potential
complexity of increasing the concerns of a ContentItem model.

There is concern that the model could become a "god" model as the initial
proposal tried to avoid. We agreed that we should not use the model layer
for logic where possible and instead use supplementary classes. This would allow
us to keep our models "thin".

### Option 3

This option was accepted with some uncertainty of the naming that should be
used. It was decided to use the original proposal of "Documents" and
"Editions" as these are concepts already in use in GOV.UK publishing - with a
synonymous meaning. There was concern that not all content the Publishing API
stores is considered a "document", however it was felt that the use of
the term "document" was already in use within Publishing and this would not be
introducing a fresh problem.

The key aspects that influenced choosing this was:
* It offered a simple means to lock requests for concurrency
* It provided a simpler interface for someone to look up which content is
  in draft or in live
* It made the distinctions between translations of a piece of content clearer.

### Option 4

This was rejected. It was felt that this option was letting our application
concerns influence our schema too greatly. There was also not a clear
difference between which model would have responsibility for what data, which
we felt would make it a challenging abstraction to explain.

### Option 5

This was initially delayed for further investigation. However it transpired
that to have a unique index between base_path and state in PostgreSQL we would
need this. Thus it was accepted and implemented.

### Option 6

This was rejected due to it not being a current concern, it is an idea that
may be revisited as part of work to include workflow history and/or to support
a greater array of workflow states.

### Option 7

This was rejected since we are not at a point where we are concerned with
different entities sharing the concept of base_path. It was felt that until
these are a concern this idea offered an increase in complexity without any
clear benefits.

This will be reconsidered if we pursue ideas such as "redirects as first-class
citizens".

