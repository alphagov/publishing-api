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

link_set_linked_editions AS (
  SELECT
    editions.*,
    links.target_content_id,
    links.link_type,
    links.edition_id,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    row_number() OVER (
      PARTITION BY
        documents.content_id,
        links.link_type,
        links.target_content_id
      ORDER BY (
        CASE
          WHEN (documents.locale =:primary_locale) THEN 0
          ELSE 1
        END
      )
    ) AS row_number
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
),

edition_linked_editions AS (
  SELECT
    editions.*,
    links.target_content_id,
    links.link_type,
    links.edition_id,
    links.position,
    links.id AS link_id,
    documents.content_id,
    documents.locale,
    row_number() OVER (
      PARTITION BY
        documents.content_id,
        links.link_type,
        links.target_content_id
      ORDER BY (
        CASE
          WHEN (documents.locale =:primary_locale) THEN 0
          ELSE 1
        END
      )
    ) AS row_number
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
)

SELECT editions.* FROM (
  SELECT * FROM link_set_linked_editions
  UNION
  SELECT * FROM edition_linked_editions
) AS editions
WHERE editions.row_number = 1
ORDER BY
  editions.link_type ASC, editions.position ASC, editions.link_id DESC
