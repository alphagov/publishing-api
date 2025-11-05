-- linked_to_editions
SELECT editions.* FROM (
  SELECT
    editions.*,
    links.link_type,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    link_sets.content_id AS source_content_id,
    row_number() OVER (
      PARTITION BY
        documents.content_id,
        links.link_type,
        link_sets.content_id
      ORDER BY (
        CASE
          WHEN (documents.locale =:primary_locale) THEN 0
          ELSE 1
        END
      )
    ) AS row_number
  FROM editions
  INNER JOIN documents ON editions.document_id = documents.id
  INNER JOIN links ON documents.content_id = links.target_content_id
  INNER JOIN link_sets ON links.link_set_content_id = link_sets.content_id
  WHERE
    (
      (link_sets.content_id, links.link_type) IN (:content_id_tuples)
    )
    AND editions.content_store =:content_store
    AND documents.locale IN (:locale_with_fallback)
    AND editions.document_type NOT IN (:non_renderable_formats)
    AND (
      links.link_type IN (:unpublished_link_types)
      OR editions.state != 'unpublished'
    )
  UNION
  SELECT
    editions.*,
    links.link_type,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    source_documents.content_id AS source_content_id,
    row_number() OVER (
      PARTITION BY
        documents.content_id,
        links.link_type,
        source_editions.id
      ORDER BY (
        CASE
          WHEN (documents.locale =:primary_locale) THEN 0
          ELSE 1
        END
      )
    ) AS row_number
  FROM editions
  INNER JOIN documents ON editions.document_id = documents.id
  INNER JOIN links ON documents.content_id = links.target_content_id
  INNER JOIN editions AS source_editions ON links.edition_id = source_editions.id
  INNER JOIN documents AS source_documents ON source_editions.document_id = source_documents.id
  WHERE
    ((source_editions.id, links.link_type) IN (:edition_id_tuples))
    AND editions.content_store =:content_store
    AND documents.locale IN (:locale_with_fallback)
    AND editions.document_type NOT IN (:non_renderable_formats)
    AND (
      links.link_type IN (:unpublished_link_types)
      OR editions.state != 'unpublished'
    )
) AS editions
WHERE editions.row_number = 1
ORDER BY
  editions.link_type ASC, editions.position ASC, editions.link_id DESC
