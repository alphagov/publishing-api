Dataloader SQL Queries
======================

The GraphQL dataloaders have to perform a complex query.

As input, we have a list of source editions and link types. As output, we have a list of lists of target editions (
one list of target editions for every source edition / link type combination).

We need to join through links, documents, editions and unpublishings, and correctly handle various ways we can get
duplicate candidate target editions. For example:

- There's more than one locale for the target content_id
- There's more than one locale for the target content_id, and the editions have different states (published / withdrawn)
- The source edition has both link set links and edition links for the same link type

For performance reasons, ideally this should happen in a single SQL query, rather than several.

The SQL files in this directory perform this query for "direct" and "reverse" links.

This README covers how to work with these SQL files, and some of the SQL features they use which may be unfamiliar to
some developers.

Working with the SQL files
--------------------------

Running the queries from a rails console:

```ruby
sql = File.read(Rails.root.join("app/graphql/sources/queries/linked_to_editions.sql"))
homepage_content_id = "f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a"
sql_params = {
  sources_and_link_types: [
    {edition_id: nil, content_id: homepage_content_id, link_type: "popular_links"},
    {edition_id: nil, content_id: homepage_content_id, link_type: "primary_publishing_organisation"},
  ].to_json,
  locale_with_fallback: %w[en],
  primary_locale: "en",
  content_store: "live",
  unpublished_link_types: Link::PERMITTED_UNPUBLISHED_LINK_TYPES,
  non_renderable_formats: Edition::NON_RENDERABLE_FORMATS,
}
Edition.find_by_sql([sql, sql_params])
```

Getting the `EXPLAIN ANALYSE` results from the rails console:

```ruby
bound_sql = ActiveRecord::Base.send(:sanitize_sql_array, [sql, sql_params])
plan = ActiveRecord::Base.connection.execute("EXPLAIN ANALYZE #{bound_sql}")

puts plan.map { |r| r['QUERY PLAN'] }.join("\n")
```

Running the queries from plain `psql`:

```bash
# Note - you need to be quite careful with quotes and shell escaping for this to work.
# All strings must be wrapped with single quotes, sources_and_link_types must be JSON

sources_and_link_types="'"'[{"content_id": "f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a", "link_type": "primary_publishing_organisation"}]'"'"
locale_with_fallback="'en'"
primary_locale="'en'"
content_store="'live'"
unpublished_link_types="'parent'"
non_renderable_formats="'redirect','gone'"

psql \
  --dbname publishing_api_development \
  --set "sources_and_link_types=$sources_and_link_types" \
  --set "locale_with_fallback=$locale_with_fallback" \
  --set "primary_locale=$primary_locale" \
  --set "content_store=$content_store" \
  --set "unpublished_link_types=$unpublished_link_types" \
  --set "non_renderable_formats=$non_renderable_formats" \
  --file app/graphql/sources/queries/linked_to_editions.sql
```

SQL features to be aware of
---------------------------

### jsonb_to_recordset

### Common Table Expressions (CTEs)

### SELECT DISTINCT ON

### Window functions

### UNION ALL
