# Decision Record: Update representation of change history

## Context

Various pages on GOV.UK include the "change history" of the page, usually hidden behind a "See all updates" link.

There are currently several different ways that change notes / change history can be sent to publishing API:

1) `organisation`, `service_manual_guide`, `statistics_announcement` and `world_location` schemas have a `change_note`
   (note: singular) field in details
2) 14 schemas have a `change_history` field in details (which is an array of `{ note: ..., public_timestamp: ...}` hashes)
3) All schemas allow a top level `change_note` field
4) `manual` and `hmrc_manual` schemas have a `change_notes` (note: plural) field in details (these don't appear to be
   handled by the mechanism in this ADR)

There's a database table `change_notes` which stores the note, it's public_timestamp, and the edition it belongs to.

This was [introduced in 2016](https://github.com/alphagov/publishing-api/pull/552), to prevent publishing apps from
having to send the entire change history for an edition in the PutContent call. 

Unfortunately, querying the change notes for a document can be expensive when the document has a large number of
editions. Currently, [the query](https://github.com/alphagov/publishing-api/blob/6ba2c2de456dd60ac9535980a72cafd30d0caba2/app/presenters/queries/change_history.rb#L32-L36)
looks like this:

```ruby
ChangeNote
  .joins(:edition)
  .where(editions: { document: edition.document })
  .where("user_facing_version <= ?", edition.user_facing_version)
  .where.not(public_timestamp: nil)
```

Note that we have to look at the editions table to get the editions for the document in question as well as the change
notes table to get the change notes.

Even though there are indexes on both tables, this can get fairly expensive. If a document has (say) 5,000 editions,
postgres can use the index on `editions(document_id, user_facing_version)` to find the editions efficiently, but
afterwards it needs to find ~5,000 change notes in the other table. Even though there's an index on
`change_notes(edition_id)`, finding all the change notes means scanning the index ~5,000 times.

<details>
<summary>Example query plan</summary>

```
                                                                                 QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.86..1707.33 rows=7 width=89) (actual time=0.066..15.183 rows=1928 loops=1)
   ->  Index Scan using index_editions_on_document_id_and_user_facing_version on editions  (cost=0.44..553.33 rows=137 width=4) (actual time=0.048..3.637 rows=4906 loops=1)
         Index Cond: ((document_id = 424976) AND (user_facing_version <= 4906))
   ->  Index Scan using index_change_notes_on_edition_id on change_notes  (cost=0.42..8.41 rows=1 width=89) (actual time=0.002..0.002 rows=0 loops=4906)
         Index Cond: (edition_id = editions.id)
         Filter: (public_timestamp IS NOT NULL)
 Planning Time: 0.581 ms
 Execution Time: 15.382 ms
(8 rows)
```

Note in particular the `loops=4906` on the second index scan.

</details>

If we changed the database schema so that change notes were in the same table as the document id / user facing version
then we could find them much more efficiently.

## Decision

We will add `change_note` and `change_note_timestamp` columns to the editions table, migrate existing data from the
`note` and `public_timestamp` columns in `change_notes`, and then drop the `change_notes` table.

<details>
<summary>Aside on public_timestamp / change_note_timestamp</summary>

The situation with `change_notes.public_timestamp` is a little confusing. How is it different from
`editions.public_updated_at`?

If the entry in `change_notes` comes from the `change_note` at the top level in the payload, or from the
`details.change_note` field, `public_timestamp` will be set to the `public_updated_at` value
in the PutContent request, if there is one, or the current time otherwise. Using the current time as a default
is different to the logic for `editions.public_updated_at`, which will use the current time only if it's a major change,
otherwise using the `public_updated_at` of the previous edition. Additionally, prior to 8a5366af in June 2019 it
would always use the current time (which was a bug).

Further complicating things, if the change note comes from `details.change_history` (which is an array of
`{ note: ..., public_timestamp: ...}`), we take the first `public_timestamp` from the `change_history` - in which case
it can be a completely different (publisher specified) timestamp to the edition.

This all feels like a terrible mess, and although it would be nice to clean it up, I think it would add too much extra
complexity to this ADR to change it at the same time as amending the database schema.

Even though we're not addressing it in this ADR, it does seem like a good idea to remove the complexity of change notes
potentially having different public timestamps to the editions they belong to. Possible future work there.
</details>

<details>
<summary>Aside on edition / change_note cardinality</summary>

From looking at the database schema, I'd assumed that there would only be one change note for each edition.

It turns out there's no unique index on `change_notes.edition_id` though, so it's actually possible to have several
change notes for the same edition. Indeed, there are a few (about 500) editions that have several change notes. These
are all superseded editions from before 2018, and they're all either `specialist_documents` or `service_manual_guide`
schemas, so I suspect they're echoes of long forgotten bugs in specialist publisher / service manual publisher.

I'm pretty confident they can be safely ignored - we can just pick a note at random (first, last, whatever) if there
are several for a given edition.

</details>

<details>
<summary>Aside on NULL public_timestamps</summary>

Around 100 `change_notes` (~0.01% of them) have `NULL` `public_timestamp` fields. They get ignored by the
`.where.not(public_timestamp: nil)` clause in the change history query though.

I'd probably lean towards not copying over these `NULL` `public_timestamp` change notes, and maybe putting a constraint
in the database to ensure that any edition that has a non-NULL `change_note` also has a non-NULL `change_note_timestamp`.

This should allow a slight simplification of the database query.
</details>

### Implementation plan

1) Add `change_note` and `change_note_timestamp` columns to the editions table.
2) Update the code in publishing API to write to both the new columns in the `editions` table and the `change_notes`
   table, while continuing to read change notes from the `change_notes` table.
3) Populate the new columns on `editions` with the contents of the `note` and `public_timestamp` fields from the
   `change_notes` table.
4) Consider whether any changes to the indexes on `editions` are worthwhile (probably the existing
   `index_editions_on_document_id_and_user_facing_version` is good enough though)
5) Update the code in publishing API to read from the new columns in the `editions` table, and stop writing to the
   `change_notes` table.
6) Delete the `ChangeNote` model from publishing API
7) Drop the `change_notes` table


## Consequences

### Queries to get change notes for a document will be much faster

🚀

Thanks to all the columns of interest being in the same table, we'll be able to do a much simpler index scan.

### The database schema will be simpler

We'll have fewer tables, which should make the schema a little easier to understand.

### The timestamp situation will still be confusing

As mentioned above in "Aside on public_timestamp / change_note_timestamp", the situation with change note timestamps
is very confusing. We're not planning on addressing that issue in this ADR, so it will continue to be confusing.

By moving and renaming the field, we'll also be adding another crumb to the trail of clues you have to follow to work
out what on earth is going on with timestamps in publishing-api.

## Doesn't help us remove superseded editions from the editions table

Publishing API's database is huge, largely because we store every historical version of every edition.

Historical versions of editions are currently stored in the `editions` table, with the `content_store` column set to
`NULL` and the `state` column set to `'superseded'`.

We need these historical records mainly because we need to look up change notes for editions, so we need the mapping
from `document_id` to `edition_id`.

Moving change notes into the editions table wouldn't make this situation any better, and might further entrench the
pattern of keeping `superseded` editions in the same table as live / draft editions.

This is annoying, because publishing API database dumps are very large because of superseded editions, and we believe
there's a performance cost to all queries that hit the editions table.

## Alternatives considered

### Denormalising change history by adding document_id / user_facing_version columns

This was explored [in this PR](https://github.com/alphagov/publishing-api/pull/3743).

The drawbacks of this approach are:

- We're storing a little more data (a small amount though, basically irrelevant)
- We're storing "which edition belongs to which document" in two places - the editions table, and the change notes table. Which feels like "bad" database design. In practice, editions never move from one document to another, and user_facing_version never changes once an edition is created. So I don't think there's any realistic data hazard in doing it this way.
