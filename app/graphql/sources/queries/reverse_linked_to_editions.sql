-- reverse_linked_to_editions
WITH query_input AS (
  SELECT query_input.*
  FROM
    json_to_recordset(:query_input::json) AS query_input (
      content_id uuid,
      link_type varchar
    )
  LIMIT (:query_input_count) -- noqa: AM09
),

edition_linked_editions AS (
  -- NOTE: we're not using DISTINCT ON (links.id) here because the tests check that
  --       if we have multiple links of the same link_type / target_content_id pointing
  --       at editions of the same document with different locales, we should only get
  --       the document with the best locale (rather than all of them).
  --       It's not clear if the behaviour we're testing for is correct though.
  --       Reverse edition links are a niche feature.
  SELECT DISTINCT ON (documents.content_id, links.link_type, links.target_content_id)
    editions.*,
    links.target_content_id,
    links.link_type,
    links.edition_id,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    documents.locale =:primary_locale AS is_primary_locale
  FROM editions
  INNER JOIN documents ON editions.document_id = documents.id
  INNER JOIN links ON editions.id = links.edition_id
  INNER JOIN query_input ON links.target_content_id = query_input.content_id AND links.link_type = query_input.link_type
  WHERE
    editions.content_store =:content_store
    AND documents.locale IN (:primary_locale,:secondary_locale)
    AND editions.document_type NOT IN (:non_renderable_formats)
    AND (
      links.link_type IN (:unpublished_link_types)
      OR editions.state != 'unpublished'
    )
  ORDER BY documents.content_id ASC, links.link_type ASC, links.target_content_id ASC, is_primary_locale DESC
),

link_set_linked_editions AS (
  SELECT DISTINCT ON (links.id)
    editions.*,
    links.target_content_id,
    links.link_type,
    links.edition_id,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    documents.locale =:primary_locale AS is_primary_locale
  FROM editions
  INNER JOIN documents ON editions.document_id = documents.id
  INNER JOIN links ON documents.content_id = links.link_set_content_id
  INNER JOIN query_input ON links.target_content_id = query_input.content_id AND links.link_type = query_input.link_type
  WHERE
    editions.content_store =:content_store
    AND documents.locale IN (:primary_locale,:secondary_locale)
    AND editions.document_type NOT IN (:non_renderable_formats)
    AND (
      links.link_type IN (:unpublished_link_types)
      OR editions.state != 'unpublished'
    )
  ORDER BY links.id ASC, is_primary_locale DESC
)

SELECT editions.* FROM (
  SELECT * FROM link_set_linked_editions
  UNION
  SELECT * FROM edition_linked_editions
) AS editions
ORDER BY
  editions.link_type ASC, editions.position ASC, editions.link_id DESC
