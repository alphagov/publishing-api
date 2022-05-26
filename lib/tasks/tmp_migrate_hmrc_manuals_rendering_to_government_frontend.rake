# As part of decommissioning manuals-frontend we are moving all previously published
# manuals to government-frontend as the rendering app. As hnmrc-manuals-api has no DB
# itself to update and republish from, we are instead updating the rendering app directly
# in the publishing_api via this temporary Rake task. It will only update editions that are currently
# live in the content-store, drafts will be updated when published from the API.

desc "Migrate HMRC manuals rendering app to government-frontend"
task tmp_migrate_hmrc_manuals_rendering_to_government_frontend: :environment do
  hmrc_manuals = Document.presented.where(editions: { publishing_app: "hmrc-manuals-api" })

  hmrc_manuals.each do |document|
    edition = document.live

    next if edition.blank?

    edition.update!(rendering_app: "government-frontend")
    Commands::V2::RepresentDownstream.new.call(document.content_id)
  end
end
