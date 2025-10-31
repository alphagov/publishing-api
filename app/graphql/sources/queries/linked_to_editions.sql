WITH sources_and_link_types AS (
  SELECT *
  FROM jsonb_to_recordset(
    :sources_and_link_types::jsonb
  ) AS (edition_id integer,content_id uuid,link_type text)
),

all_links AS (
  SELECT
    salt.content_id AS source_content_id,
    l.*
  FROM sources_and_link_types AS salt
  INNER JOIN links AS l ON salt.edition_id = l.edition_id AND salt.link_type = l.link_type
  UNION ALL
  SELECT
    salt.content_id AS source_content_id,
    links.*
  FROM sources_and_link_types AS salt
  INNER JOIN links ON salt.content_id = links.link_set_content_id AND salt.link_type = links.link_type
)

-- noqa: disable=AM04
SELECT DISTINCT ON (l.source_content_id, l.link_type, l.position, l.id)
  d.*,
  e.*,
  l.link_type,
  l.source_content_id
-- noqa: enable=AM04
FROM editions AS e
INNER JOIN documents AS d ON e.document_id = d.id AND d.locale IN (:locale_with_fallback)
INNER JOIN all_links AS l ON d.content_id = l.target_content_id
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
  l.source_content_id ASC,
  l.link_type ASC,
  l.position ASC,
  l.id DESC,
  d.locale =:primary_locale DESC;
