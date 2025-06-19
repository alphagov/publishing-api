desc "Tidies up local authority editions"
task temp_tidy_local_authority_editions: :environment do
  Edition.where(publishing_app: "local-links-manager", schema_name: "external_content").destroy_all
end
