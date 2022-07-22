# Following decommissioning of manuals-frontend we are improving simplicity of rendering
# these manuals in government-frontend by adding the manual title to the manual sections
# in the publishing_api via this temporary Rake task. It will only update
# sections of editions that are currently live in the content-store,
# drafts will be updated when published from the API.

def update_hmrc_manual_section_titles(dry_run: false)
  hmrc_manual_sections = Document.presented.where(editions: { publishing_app: "hmrc-manuals-api", document_type: "hmrc_manual_section" })

  hmrc_manual_sections.each do |document|
    edition = document.live

    next if edition.blank?

    details = edition.details
    details[:manual].delete(:title)

    puts("Removing HMRC Manual title from HMRC Section #{document.content_id}")
    unless dry_run
      edition.update!(details: details)
      Commands::V2::RepresentDownstream.new.call(document.content_id)
    end
  end
end

namespace :tmp_update_hmrc_manual_sections do
  desc "Show hmrc_manual_section items that will be updated with the title of the containing manual"
  task dry_run: :environment do
    puts("DRY RUN (no actual changes will be saved)")
    update_hmrc_manual_section_titles(dry_run: true)
  end

  desc "Update hmrc_manual_section items with the title of the containing manual"
  task go: :environment do
    update_hmrc_manual_section_titles
  end
end
