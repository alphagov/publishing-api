desc "Migrate HMRC manuals from live to beta"
task tmp_migrate_hmrc_manuals_from_live_to_beta: :environment do
  hmrc_manuals = Document.presented.where(editions: { publishing_app: "hmrc-manuals-api" })

  hmrc_manuals.each do |document|
    edition = document.live

    next if edition.blank?

    edition.update!(phase: "beta")
    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(document.content_id)
    end
  end
end
