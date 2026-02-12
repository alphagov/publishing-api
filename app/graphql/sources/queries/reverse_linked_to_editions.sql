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
  SELECT DISTINCT ON (documents.content_id, links.target_content_id)
    editions.*,
    links.link_type,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    TRUE AS is_primary_locale,
    links.target_content_id
  FROM editions
  INNER JOIN documents ON editions.document_id = documents.id
  INNER JOIN links ON editions.id = links.edition_id
  INNER JOIN query_input ON links.target_content_id = query_input.content_id AND links.link_type = query_input.link_type
  LEFT JOIN unpublishings ON editions.id = unpublishings.edition_id
  WHERE
    editions.content_store =:content_store
    AND documents.locale =:primary_locale
    AND editions.document_type NOT IN (:non_renderable_formats)
    AND (
      editions.state != 'unpublished'
      OR
      (
        links.link_type IN (:unpublished_link_types)
        AND
        unpublishings.type = 'withdrawal'
      )
    )
  ORDER BY documents.content_id ASC, links.target_content_id ASC
),

link_set_linked_editions AS (
  SELECT DISTINCT ON (links.id)
    editions.*,
    links.link_type,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    documents.locale =:primary_locale AS is_primary_locale,
    links.target_content_id
  FROM editions
  INNER JOIN documents ON editions.document_id = documents.id
  INNER JOIN links ON documents.content_id = links.link_set_content_id
  INNER JOIN query_input ON links.target_content_id = query_input.content_id AND links.link_type = query_input.link_type
  LEFT JOIN unpublishings ON editions.id = unpublishings.edition_id
  WHERE
    editions.content_store =:content_store
    AND documents.locale IN (:primary_locale,:secondary_locale)
    AND editions.document_type NOT IN (:non_renderable_formats)
    AND (
      editions.state != 'unpublished'
      OR
      (
        links.link_type IN (:unpublished_link_types)
        AND
        unpublishings.type = 'withdrawal'
      )
    )
    -- skip any links that we already found in edition_linked_editions:
    AND NOT EXISTS (
      SELECT FROM edition_linked_editions
      WHERE
        edition_linked_editions.target_content_id = links.target_content_id
        AND edition_linked_editions.link_type = links.link_type
    )
  ORDER BY links.id ASC, is_primary_locale DESC
)

SELECT editions.* FROM (
  SELECT * FROM link_set_linked_editions
  UNION ALL
  SELECT * FROM edition_linked_editions
) AS editions
ORDER BY
  editions.link_type ASC, editions.position ASC, editions.link_id DESC
