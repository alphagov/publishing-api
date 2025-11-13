-- linked_to_editions
WITH link_set_linked_editions AS (
  SELECT DISTINCT ON (links.id)
    editions.*,
    links.link_type,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    links.link_set_content_id AS source_content_id
  FROM editions
  INNER JOIN documents ON editions.document_id = documents.id
  INNER JOIN links ON documents.content_id = links.target_content_id
  WHERE
    (
      (links.link_set_content_id, links.link_type) IN (:content_id_tuples)
    )
    AND editions.content_store =:content_store
    AND documents.locale IN (:primary_locale,:secondary_locale)
    AND editions.document_type NOT IN (:non_renderable_formats)
    AND (
      links.link_type IN (:unpublished_link_types)
      OR editions.state != 'unpublished'
    )
  ORDER BY links.id, (
    CASE
      WHEN (documents.locale =:primary_locale) THEN 0
      ELSE 1
    END
  )
),

edition_linked_editions AS (
  SELECT DISTINCT ON (links.id)
    editions.*,
    links.link_type,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    source_documents.content_id AS source_content_id
  FROM editions
  INNER JOIN documents ON editions.document_id = documents.id
  INNER JOIN links ON documents.content_id = links.target_content_id
  INNER JOIN editions AS source_editions ON links.edition_id = source_editions.id
  INNER JOIN documents AS source_documents ON source_editions.document_id = source_documents.id
  WHERE
    ((source_editions.id, links.link_type) IN (:edition_id_tuples))
    AND editions.content_store =:content_store
    AND documents.locale IN (:primary_locale,:secondary_locale)
    AND editions.document_type NOT IN (:non_renderable_formats)
    AND (
      links.link_type IN (:unpublished_link_types)
      OR editions.state != 'unpublished'
    )
  ORDER BY links.id, (
    CASE
      WHEN (documents.locale =:primary_locale) THEN 0
      ELSE 1
    END
  )
),

-- Get the types of the edition_linked_editions
edition_link_types AS (
  SELECT DISTINCT
    source_content_id,
    link_type
  FROM edition_linked_editions
),

-- Exclude links of those types from the link_set_linked_editions
intact_link_set_linked_editions AS (
  SELECT link_set_linked_editions.*
  FROM link_set_linked_editions
  LEFT JOIN edition_link_types
    ON (
      link_set_linked_editions.source_content_id = edition_link_types.source_content_id
      AND link_set_linked_editions.link_type = edition_link_types.link_type
    )
  WHERE edition_link_types.link_type IS NULL
)

SELECT editions.* FROM (
  SELECT * FROM intact_link_set_linked_editions
  UNION ALL
  SELECT * FROM edition_linked_editions
) AS editions
ORDER BY
  editions.link_type ASC, editions.position ASC, editions.link_id DESC
