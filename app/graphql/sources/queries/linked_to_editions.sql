-- linked_to_editions
WITH query_input AS (
  SELECT query_input.*
  FROM
    json_to_recordset(:query_input::json) AS query_input (
      edition_id integer,
      content_id uuid,
      link_type varchar
    )
  LIMIT (:query_input_count) -- noqa: AM09
),

edition_linked_editions AS (
  SELECT DISTINCT ON (links.id)
    editions.*,
    links.link_type,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    documents.locale =:primary_locale AS is_primary_locale,
    source_documents.content_id AS source_content_id
  FROM editions
  INNER JOIN documents ON editions.document_id = documents.id
  INNER JOIN links ON documents.content_id = links.target_content_id
  INNER JOIN editions AS source_editions ON links.edition_id = source_editions.id
  INNER JOIN query_input ON source_editions.id = query_input.edition_id AND links.link_type = query_input.link_type
  INNER JOIN documents AS source_documents ON source_editions.document_id = source_documents.id
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
  ORDER BY links.id ASC, is_primary_locale DESC
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
    links.link_set_content_id AS source_content_id
  FROM editions
  INNER JOIN documents ON editions.document_id = documents.id
  INNER JOIN links ON documents.content_id = links.target_content_id
  INNER JOIN
    query_input
    ON links.link_set_content_id = query_input.content_id AND links.link_type = query_input.link_type
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
        edition_linked_editions.source_content_id = links.link_set_content_id
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
