WITH content_ids_and_link_types AS (
  SELECT
    content_id,
    link_type
  FROM jsonb_to_recordset(:content_ids_and_link_types::jsonb) AS (content_id uuid,link_type text)
),

all_links AS (
  SELECT l.*
  FROM content_ids_and_link_types AS cialt
  INNER JOIN links AS l ON cialt.content_id = l.target_content_id AND cialt.link_type = l.link_type
),

source_editions AS (
  -- noqa: disable=AM04
  SELECT DISTINCT ON (l.edition_id IS NULL, l.target_content_id, l.link_type, d.content_id)
    d.*,
    e.*,
    l.link_type,
    l.position,
    l.id AS link_id,
    l.target_content_id
  -- noqa: enable=AM04
  FROM editions AS e
  INNER JOIN documents AS d ON e.document_id = d.id AND d.locale IN (:locale_with_fallback)
  INNER JOIN all_links AS l ON d.content_id = l.link_set_content_id OR e.id = l.edition_id
  LEFT OUTER JOIN unpublishings AS u ON e.id = u.edition_id
  WHERE (
    e.state != 'unpublished'
    OR (
      l.link_type IN (:unpublished_link_types)
      AND u.type = 'withdrawal'
    )
  )
  AND e.content_store =:content_store
  AND e.document_type NOT IN (:non_renderable_formats)
  ORDER BY
    l.edition_id IS NULL ASC, -- edition links first
    l.target_content_id ASC,
    l.link_type ASC,
    d.content_id ASC,
    d.locale =:primary_locale DESC
)

SELECT * FROM source_editions
ORDER BY
  target_content_id ASC,
  link_type ASC,
  position ASC,
  link_id DESC;
