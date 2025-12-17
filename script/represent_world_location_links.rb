puts "Fetching content IDs"

sql = %{
WITH
editions_live AS (
  SELECT
    editions.id,
    documents.content_id,
    editions.base_path,
    editions.title
  FROM editions
  INNER JOIN documents ON documents.id = editions.document_id
  LEFT JOIN unpublishings ON editions.id = unpublishings.edition_id
  WHERE TRUE
  AND content_store = 'live'
),
location_links AS (
  SELECT *
  FROM links
  WHERE link_type IN ('worldwide_organisation', 'world_locations', 'world_location_news')
),
edition_links AS (
  SELECT
    sources.id AS source_edition_id,
    sources.content_id AS source_content_id,
    sources.base_path AS source_base_path,
    targets.id AS target_edition_id,
    targets.content_id AS target_content_id,
    targets.base_path AS target_base_path,
    targets.title AS target_title,
    links.link_type AS type,
    links.position
  FROM location_links AS links
  INNER JOIN editions_live AS sources
    ON (sources.id = links.edition_id)
  INNER JOIN editions_live AS targets
    ON (targets.content_id = links.target_content_id)
),
link_set_links AS (
  SELECT
    sources.id AS source_edition_id,
    sources.content_id AS source_content_id,
    sources.base_path AS source_base_path,
    targets.id AS target_edition_id,
    targets.content_id AS target_content_id,
    targets.base_path AS target_base_path,
    targets.title AS target_title,
    links.link_type AS type,
    links.position
  FROM location_links AS links
  INNER JOIN editions_live AS sources
    ON (sources.content_id = links.link_set_content_id)
  INNER JOIN editions_live AS targets
  ON (targets.content_id = links.target_content_id)
),
all_location_links AS (
  SELECT * FROM edition_links
  UNION SELECT * FROM link_set_links
),
all_document_ids AS (
  SELECT
    editions_a.document_id
  FROM editions AS editions_a
  INNER JOIN all_location_links AS links_a_b ON links_a_b.source_edition_id = editions_a.id
  INNER JOIN all_location_links AS links_b_c ON links_b_c.source_edition_id = links_a_b.target_edition_id
  INNER JOIN editions AS editions_b ON editions_b.id = links_a_b.target_edition_id
  INNER JOIN editions AS editions_c ON editions_c.id = links_b_c.target_edition_id
  WHERE TRUE
  AND editions_a.content_store = 'live'
  AND links_a_b.type = 'world_locations'
  AND editions_b.document_type = 'world_location'
  AND links_b_c.type = 'world_location_news'
  AND editions_c.document_type = 'world_location_news'
UNION
  SELECT
    editions_a.document_id
  FROM editions AS editions_a
  INNER JOIN all_location_links AS links_a_b ON links_a_b.source_edition_id = editions_a.id
  INNER JOIN all_location_links AS links_b_c ON links_b_c.source_edition_id = links_a_b.target_edition_id
  INNER JOIN all_location_links AS links_c_d ON links_c_d.source_edition_id = links_b_c.target_edition_id
  INNER JOIN editions AS editions_b ON editions_b.id = links_a_b.target_edition_id
  INNER JOIN editions AS editions_c ON editions_c.id = links_b_c.target_edition_id
  INNER JOIN editions AS editions_d ON editions_d.id = links_c_d.target_edition_id
  WHERE TRUE
  AND editions_a.content_store = 'live'
  AND links_a_b.type = 'worldwide_organisation'
  AND links_b_c.type = 'world_locations'
  AND editions_c.document_type = 'world_location'
  AND links_c_d.type = 'world_location_news'
  AND editions_d.document_type = 'world_location_news'
  GROUP BY editions_a.document_id
)
SELECT DISTINCT
  documents.content_id
FROM all_document_ids
INNER JOIN documents ON documents.id = all_document_ids.document_id
}

content_ids = ActiveRecord::Base.connection.execute(sql).pluck("content_id")

puts "Found #{content_ids.length} content IDs"

if content_ids.length > 50_000 # We expect ~45k content IDs
  puts "Too many content IDs. Exiting."
  exit
end

Rails.application.load_tasks

puts "Invoking represent_downstream:content_id for each content ID"

batch_size = 1000
processed_count = 0
content_ids.each_slice(batch_size) do |batch|
  Rake::Task["represent_downstream:content_id"].invoke(batch)
  processed_count += batch_size
  puts("Processed #{processed_count} content IDs")
end

puts "Done"
