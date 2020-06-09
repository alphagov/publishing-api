# Decision record: use event sourcing

## Context

The aim of the publishing platform project is to simplify GOV.UK's technical
architecture and make it easier to iterate quickly.

We plan to build new features to support a write api and shared workflow features.

One of the sources of complexity in the current architecture is that state is
distributed across many microservices and there's no way to verify whether the
overall system is in a valid state.

This leads to insidious bugs such as [this one](https://github.com/alphagov/whitehall/pull/1974) which are hard to debug.

We built a [prototype](http://www.slideshare.net/dgheath21/2015-0902-transaction-log-prototype) to investigate whether an [event sourcing](http://martinfowler.com/eaaDev/EventSourcing.html) approach might
work for us, and felt that the pattern provides a number of benefits.

Firstly it gives us an audit trail out of the box, a feature which we've hoped to have for some time.

Secondly, it will make it easier to respond to changing requirements because we can use the event log to modify or build new derived representations at any point in time.

Lastly it addresses the issue of data consistency across the platform by providing a single point of truth against which other systems can be validated or potentially rebuilt from scratch.

We also have a requirement that some data is updated synchronously when making calls to the publishing API. This synchronously updated data will need to be held within the same database as the publishing API so that we can guarantee consistency.

Other data (for example rummager, content store) can be held in a separate systems and updated asynchronously.

## Decision

We'll adopt the event sourcing pattern for the publishing api.

All operations which may mutate the state of the publishing platform should be logged as an event in the publishing API.

The publishing API will store some derived representations locally in its own database and update them synchronously with the logging of the event, within a database transaction.

Other derived representations will be updated asynchronously, e.g:

* content store
* rummager

## Status

Accepted.

## Consequences

Since this is a pattern which we don't have much experience of, we'll need to be open to learning and reviewing our approach as we go forward.

In particular the choices around what data is updated synchronously/asynchronously should be considered carefully to balance the trade-off between speed of api calls and the value of consistent reads to api clients.

There's some ideas around replaying of the event log to rebuild derived systems but until we have a concrete use-case for this there's no point in speculating about the implementation.
