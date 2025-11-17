Dataloader SQL Queries
======================

The GraphQL dataloaders have to perform complex queries.

As input, we have a list of source editions and link types. As output, we have a list of lists of target editions (
one list of target editions for every source edition / link type combination).

We need to join through links, documents, editions and unpublishings, and correctly handle various ways we can get
duplicate candidate target editions. For example:

- There's more than one locale for the target content_id
- There's more than one locale for the target content_id, and the editions have different states (published / withdrawn)
- The source edition has both link set links and edition links for the same link type

For performance reasons, ideally this should happen in a single SQL query, rather than several.

The SQL files in this directory perform this query for "direct" and "reverse" links.

SQL features to be aware of
---------------------------

This query uses a few advanced SQL features that are worth understanding before making changes.

### Common Table Expressions (CTEs)

A **Common Table Expression** (CTE) is a way to define a temporary, named result set that you can reference later in your query.
They make complex queries easier to read and maintain by breaking them into smaller steps.

https://www.postgresql.org/docs/current/queries-with.html

For example:

```sql
WITH documents AS (
  SELECT * FROM (VALUES
    ('content 1', 'en'),
    ('content 1', 'fr'),
    ('content 2', 'en'),
    ('content 2', 'fr'),
    ('content 3', 'fr')
  ) AS documents(content_id, locale)
)

SELECT * FROM documents
```

| content\_id | locale |
| :--- | :--- |
| content 1 | en |
| content 1 | fr |
| content 2 | en |
| content 2 | fr |
| content 3 | fr |

Here we create a CTE called documents with some hardcoded values, and then `SELECT *` from the CTE.

### json_to_recordset

ActiveRecord doesn't provide a way to pass complex types as bind parameters (e.g. in
`Edition.find_by_sql([SQL, bind_parameters])`). Instead, we pass complex types to the query as JSON strings, and then
use the `json_to_recordset` SQL function to turn them into sets of records:

```sql
WITH query_input AS (
  SELECT query_input.*
  FROM
    json_to_recordset($$
    [
      {"edition_id": 1, "content_id": "00000000-0000-0000-0000-000000000000", "link_type": "foo"},
      {"edition_id": 2, "content_id": "00000000-0000-0000-0000-000000000001", "link_type": "foo"},
      {"edition_id": 3, "content_id": "00000000-0000-0000-0000-000000000002", "link_type": "foo"}
    ]
    $$::json) AS query_input (
      edition_id integer,
      content_id uuid,
      link_type varchar
    )
  LIMIT (3)
)

SELECT * FROM query_input
```

| edition\_id | content\_id | link\_type |
| :--- | :--- | :--- |
| 1 | 00000000-0000-0000-0000-000000000000 | foo |
| 2 | 00000000-0000-0000-0000-000000000001 | foo |
| 3 | 00000000-0000-0000-0000-000000000002 | foo |

Adding a `LIMIT` to the query helps the query planner work out how many records will be in the result, which results in
more accurate query plans. Without `LIMIT`, the postgres planner assumes that `json_to_recordset` will return 100 rows.

### ORDER BY boolean DESC

In our queries, we have a "primary" locale and a "secondary" locale. We want to find the documents with the "best"
locale (ideally the primary locale, if not, the secondary).

We can do this by ordering on an `is_primary_locale` column. In SQL if you order by a boolean, `FALSE` comes before
`TRUE`, so we need to order in descending order to get `TRUE` first.

```sql
WITH documents AS (
  SELECT * FROM (VALUES
    ('content 1', 'en'),
    ('content 1', 'fr'),
    ('content 2', 'en'),
    ('content 2', 'fr'),
    ('content 3', 'fr')
  ) AS documents(content_id, locale)
)

SELECT *, locale = 'en' AS is_primary_locale
FROM documents
ORDER BY is_primary_locale DESC
```

| content\_id | locale | is\_primary\_locale |
| :--- | :--- | :--- |
| content 1 | en | true |
| content 2 | en | true |
| content 1 | fr | false |
| content 2 | fr | false |
| content 3 | fr | false |

### SELECT DISTINCT ON

`DISTINCT ON` is a feature that lets you return only the **first row** for each unique value of one
or more columns. Which row counts as "first" is determined by the `ORDER BY` clause.

For example:

```sql
WITH documents AS (
  SELECT * FROM (VALUES
    ('content 1', 'en'),
    ('content 1', 'fr'),
    ('content 2', 'fr'),
    ('content 2', 'en'),
    ('content 3', 'fr')
  ) AS documents(content_id, locale)
)

SELECT DISTINCT ON(content_id) *, locale = 'en' AS is_primary_locale
FROM documents
ORDER BY content_id, is_primary_locale DESC
```

| content\_id | locale | is\_primary\_locale |
| :--- | :--- | :--- |
| content 1 | en | true |
| content 2 | en | true |
| content 3 | fr | false |

This returns the best single document for each content_id - `content 1` and `content 2` have English editions in
this example, while `content 3` only has a French edition.

### NOT EXISTS (SELECT ...)

If a source document has both LinkSet links and Edition links for the same link type, we're only interested in the
Edition links.

To skip any LinkSet links that we've already seen in the edition links, we use this `NOT EXISTS` approach.

```sql
WITH edition_links AS (
  SELECT * FROM (VALUES
    ('content 1', 'person'),
    ('content 2', 'person')
  ) AS documents(content_id, link_type)
),

link_set_links AS (
  SELECT * FROM (VALUES
    ('content 1', 'person'),
    ('content 1', 'role'),
    ('content 2', 'person'),
    ('content 2', 'role')
  ) AS documents(content_id, link_type)
  WHERE NOT EXISTS (
    SELECT FROM edition_links
    WHERE
      documents.content_id = edition_links.content_id
      AND documents.link_type = edition_links.link_type
  )
)

SELECT * FROM link_set_links
```

| content\_id | link\_type |
| :--- | :--- |
| content 1 | role |
| content 2 | role |

Note we only select the `role` link set links - we skip the ones with `link_type = 'person'` because we've already seen
those in the edition_links.

Don't be scared!
----------------

The SQL queries might look intimidating, but if you understand the concepts above, you'll be able to understand the
queries.
