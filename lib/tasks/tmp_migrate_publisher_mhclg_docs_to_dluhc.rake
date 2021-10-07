desc "Migrate mainstream publisher docs from MHCLG to DLUHC"
task migrate_publisher_mhclg_docs_to_dluhc: :environment do
  mhclg_content_id = "2e7868a8-38f5-4ff6-b62f-9a15d1c22d28"
  dluhc_content_id = "c45c316a-a4f5-42c7-b94d-d7f1821be18e"

  mhclg_content_ids = Edition
    .distinct
    .where(publishing_app: "publisher", state: %w[draft published])
    .joins(:document)
    .joins("INNER JOIN link_sets ON documents.content_id = link_sets.content_id")
    .joins("INNER JOIN links ON link_sets.id = links.link_set_id")
    .where(links: { target_content_id: mhclg_content_id, link_type: "organisations" })
    .pluck("documents.content_id")
    .uniq

  puts "#{mhclg_content_ids.count} MHCLG documents to be migrated to DLUHC\n"

  mhclg_content_ids.each do |content_id|
    Commands::V2::PatchLinkSet.call(
      content_id: content_id,
      links: { organisations: [dluhc_content_id] },
    )

    puts "Migrated document with content_id: #{content_id}"
  end
end
