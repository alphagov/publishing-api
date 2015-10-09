# Decision record: don't log events which result in an error

## Context

Recording an 'illegal' event which was rejected means that the event log will
be inconsistent with the actual state.

An attempt to replay an event history containing rejected events would
encounter errors.

## Decision

We should not record an event if we know that the client request was invalid
(e.g. invalid content item, base_path already reserved etc). Validity is
determined by the current state produced by the sequence of previous events.

## Status

Accepted.

## Consequences

any validations must be done by checking against a local copy of the system
state within a database transaction to ensure that concurrent writes do not
interfere with one another. Even synchronous calls to external systems may
incur race conditions and lead to inconsistency.

having this internal state/checking is a work in progress. In the meantime
validations will continue to be done by content store, and url arbiter. (TBD:
explain how we'll handle this intermediary stage)

Once we call to content store asynchronously, we'll need to move
responsibility for validation of content items into publishing api we'll need
to move url arbitration responsibility into publishing api as well

