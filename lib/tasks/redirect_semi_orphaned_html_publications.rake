desc "Finds HTML Publications that were deleted from their publication without being redirected to it, and fixes that"
task redirect_semi_orphaned_html_publications: :environment do
  successes = 0
  editions = Edition.where(phase: "live", rendering_app: "government-frontend", schema_name: "html_publication", state: "published")
  found = editions.count

  editions.each do |orphan_edition|
    successes += 1 if redirect_orphaned_document(orphan_edition.document)
  end

  Rails.logger.info("Of #{found} orphans, #{successes} were redirected to their parent")
end

def redirect_orphaned_document(document)
  parent_link = document.live.links.find_by(link_type: "parent")
  if parent_link.nil?
    puts("ERROR: Couldn't find parent link for #{document.content_id}")
    return false
  end

  parent = parent_link.target_documents.find_by(locale: [document.locale, "en"])
  if parent.nil?
    puts("ERROR: Couldn't find parent for #{document.content_id}")
    return false
  end

  if document.draft.present?
    Commands::V2::DiscardDraft.call(
      {
        content_id: document.content_id,
        locale: document.locale,
      },
    )
  end

  Commands::V2::Unpublish.call(
    {
      content_id: document.content_id,
      locale: document.locale,
      type: "redirect",
      alternative_path: parent.live.base_path,
    },
  )

  true
end
