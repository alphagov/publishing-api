desc "Migrate mainstream publisher docs from DLUHC to MHCLG"
task migrate_publisher_dluhc_docs_to_mhclg: :environment do
  dluhc_content_id = "c45c316a-a4f5-42c7-b94d-d7f1821be18e"
  mhclg_content_id = "1390d07f-12b3-4f55-9dd5-fec5fd9e3649"

  dluhc_content_ids = Edition
    .distinct
    .where(publishing_app: "publisher", state: %w[draft published])
    .joins(:document)
    .joins("INNER JOIN link_sets ON documents.content_id = link_sets.content_id")
    .joins("INNER JOIN links ON link_sets.id = links.link_set_id")
    .where(links: { target_content_id: dluhc_content_id, link_type: "organisations" })
    .pluck("documents.content_id")
    .uniq

  puts "#{dluhc_content_ids.count} DLUHC documents to be migrated to MHCLG\n"

  dluhc_content_ids.each do |content_id|
    document = Document.find_by(content_id:)
    new_link = Link.find_by(target_content_id: mhclg_content_id)
    updated_organisations = document.link_set.links.where(link_type: "organisations").map { |link| link.target_content_id == dluhc_content_id ? new_link : link }.pluck("target_content_id")
    Commands::V2::PatchLinkSet.call(
      {
        content_id:,
        links: {
          organisations: updated_organisations,
        },
      },
    )

    puts "Migrated document with content_id: #{document.content_id}"
  end
end
