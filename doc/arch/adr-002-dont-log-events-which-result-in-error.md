# Decision record: don't log events which result in an error

## Context

We made an architectural decision to use Event Sourcing to capture all
requests to the Publishing API that mutate its data. Please refer to
[adr-001](adr-001-use-event-sourcing-pattern.md) for more information.

There are some incoming requests to the API that are not accepted. For example,
a request to create a content item might fail validation if it is missing
mandatory fields.

## Proposal

We should not capture events for requests that are rejected by the Publishing
API.

If these events were captured in the event log, the event log have an
inconsistent view of the data that resides in the system. This is a problem
because:

- The state of the system would be harder to understand because the event log
contains information that has no bearing on the behaviour of the system
- An attempt to replay an event history containing rejected events would
encounter errors

## Decision

We should not capture events that result in an error response from the
Publishing API.

It also follows that:

In cases where an error response is returned from the Publishing API, the
internal state of the system should not be mutated.

## Status

Accepted.

## Consequences

The event log should be updated in the same transaction as changes to the
internal state of the Publishing API.

Downstream asynchronous requests should not be allowed to fail. Validations must
be performed in the Publishing API as part of the synchronous request/response
cycle.

If an asynchronous downstream request does fail, this should be regarded as a
system error to be investigated by a developer.
