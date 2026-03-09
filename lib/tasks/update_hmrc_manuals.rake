desc "Update HMRC Manual rendering app to Frontend"
task update_hmrc_manual: :environment do
  published_hmrc_manual = Edition.where(schema_name: "hmrc_manual", state: "published", document_type: "hmrc_manual")
  published_hmrc_manual.update_all(rendering_app: "frontend")
end
