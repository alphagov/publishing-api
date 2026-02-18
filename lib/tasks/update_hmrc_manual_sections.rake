desc "Update HMRC Manual Sections rendering app to Frontend"
task update_hmrc_manual_sections: :environment do
  published_hmrc_manual_sections = Edition.where(schema_name: "hmrc_manual_section", state: "published", document_type: "hmrc_manual_section")
  published_hmrc_manual_sections.update_all(rendering_app: "frontend")
end
