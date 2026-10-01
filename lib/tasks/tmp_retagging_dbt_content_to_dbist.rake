desc "Migrate mainstream publisher docs from DBT to DBIST"
task migrate_publisher_dbt_docs_to_dbist: :environment do
  dbt_content_id = "aa750cdf-7925-429d-a2b3-0d9fa47d2c48"
  dbist_content_id = "d62ba2be-4ae5-4a9c-ac19-7c1dd197deea"

  dbt_content_ids = Edition
    .distinct
    .where(publishing_app: "publisher", state: %w[draft published])
    .joins(:document)
    .joins("INNER JOIN link_sets ON documents.content_id = link_sets.content_id")
    .joins("INNER JOIN links ON link_sets.content_id = links.link_set_content_id")
    .where(links: { target_content_id: dbt_content_id, link_type: "organisations" })
    .pluck("documents.content_id")
    .uniq

  puts "#{dbt_content_ids.count} DBT documents to be migrated to DBIST\n"

  dbt_content_ids.each do |content_id|
    document = Document.find_by(content_id:)
    new_link = Link.find_by(target_content_id: dbist_content_id)
    updated_organisations = document.link_set.links.where(link_type: "organisations").map { |link| link.target_content_id == dbt_content_id ? new_link : link }.pluck("target_content_id")
    Commands::V2::PatchLinkSet.call(
      {
        content_id:,
        links: {
          organisations: updated_organisations,
        },
        bulk_publishing: true,
      },
    )

    puts "Migrated document with content_id: #{document.content_id}"
  end
end
