# Decision Record: Include Content Block Change Notes in Downstream Payloads

## Context

The content modelling team needs email alerts to be triggered when a **major update** is made to a **content block**, 
especially when that update affects other pieces of content that embed it.

This is challenging because changes to dependent content happen indirectly - when the embedding content is republished, 
it pulls in the updated content block. However, to users subscribed to email alerts for that content, these changes 
are invisible since no alert is triggered (even though the content has effectively changed).

To fix this, we need to ensure that change notes from content blocks are sent to the 
[email-alert-service](https://github.com/alphagov/email-alert-service), so that subscribers receive notifications when 
embedded content is updated.

## Solution

We will update the `EditionPresenter` to include **change notes from embedded content blocks**, in addition to the 
change notes for the content itself.

This involves:
- Fetching all links of type `embed` from the Publishing API
- Retrieving change notes for those embedded content blocks
- Including these change notes in the payload alongside those of the host document

## Consequences

Currently, the `EditionPresenter` returns the `change_notes` from the `details` hash of the edition if they are present.

To ensure consistency and accuracy, we will now fetch all change notes directly from the Publishing API’s database when 
presenting the edition. This also addresses discrepancies in time zones - specifically, Whitehall's Edition#details 
uses local time, whereas the Publishing API's presenter queries use UTC. By fetching from the Publishing API's db, we 
ensure all change notes are timestamped in UTC.
