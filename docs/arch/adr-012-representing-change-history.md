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

We will add `document_id` and `user_facing_version` columns to the `change_notes` table. These will contain a copy of
the values in the editions table, populated when the `change_note` entry is saved (and back-filled in a batch job for
old change notes).

This idea was explored [in this PR](https://github.com/alphagov/publishing-api/pull/3743).

### Implementation plan

1) Update any queries that join `change_notes` and `editions` to fully qualify `document_id` and `user_facing_version`
   columns (i.e. use `"editions"."document_id"` not just `"document_id"`) to avoid ambiguous queries once we add columns
2) Deploy `publishing-api` to all environments
3) Add the `document_id` and `user_facing_version` columns to the `change_notes` table in a database migration
4) Add an index to the `change_notes.document_id` column
5) Update the code to ensure that whenever we save `ChangeNote` models we populate the `document_id` and
   `user_facing_version` columns with the values from the referenced edition
6) Populate the new columns in `change_notes` with a rake task (or some other kind of job)
7) Update the `change_notes_for_edition` and `change_notes_for_linked_content_blocks` queries to avoid joining `editions`
8) Hopefully, see a big performance improvement in change history queries!

## Consequences

### Queries to get change notes for a document will be much faster

🚀

Thanks to all the columns of interest being in the same table, we'll be able to do a much simpler index scan.

### It will be easier for us to refactor the way we store superseded editions

Publishing API's database is huge, largely because we store every historical version of every edition.

Because we use local copies of (redacted) database dumps in our development workflow, the size of the database causes
problems for local development. Database dumps take a long time to download and restore, and use a lot of bandwidth and
disk space. A long term goal is to factor the database in such a way that we could exclude historical editions from
database dumps, to make them easier to work with in local development.

Historical versions of editions are currently stored in the `editions` table, with the `content_store` column set to
`NULL` and the `state` column set to `'superseded'`.

One reason we need these superseded editions is that we need to look up change notes for documents, so we need the
mapping from `document_id` to `edition_id`. Once we have the `document_id` column in `change_notes`, we don't need to
query editions when getting change history for a document - we only need to look at the `change_notes` table.

The fewer places where publishing-api relies on the presence of superseded editions in the editions table, the easier it
will be to refactor the schema (e.g. by moving them into a separate `superseded_editions` table, or by partitioning the
`editions` table on `content_store`).

### We'll be storing the document to edition mapping in two places

We're storing "which edition belongs to which document" in two places - the editions table, and the change notes table.

This denormalization simplifies the joins required when querying change notes, but adds a bit of data redundancy.

The main risk with data redundancy is update anomalies - for example, if we allowed editions to change which document
they belonged to, it would be possible to update the document for an edition in the `editions` table but forget to
update the other `document_id` in the `change_notes` table. In practice, editions never move from one document to
another, and `user_facing_version` never changes once an edition is created. So I don't think there's a realistic data
hazard in doing it this way.

## Alternatives considered

### Moving change notes into the editions table

A [previous version of this ADR](https://github.com/alphagov/publishing-api/blob/bb38a789c94a7a7ce9cf6769376824ab0064ecce/docs/arch/adr-012-representing-change-history.md)
considered moving the `change_notes` columns into `editions`, and then dropping the `change_notes` table.

This would have brought the same performance benefits, without needing to denormalize the database schema. However, we
felt that it was a step in the wrong direction in terms of optimising the storage of superseded editions - it would have
made it more difficult to refactor the database schema to store superseded editions separately to live / draft editions.
