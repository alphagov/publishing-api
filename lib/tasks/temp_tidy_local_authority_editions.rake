namespace :temp_tidy_local_authority_editions do
  desc "Destroys all local authority editions for a single local authority"
  task :by_content_id, [:content_id] => :environment do |_, args|
    doc = Document.find_by(content_id: args.content_id)
    if doc
      doc.editions.where(publishing_app: "local-links-manager", schema_name: "external_content").destroy_all
    else
      puts("Can't find document for #{args.content_id}")
    end
  end

  desc "Destroys all local authority editions"
  task all: :environment do
    Edition.where(publishing_app: "local-links-manager", schema_name: "external_content").destroy_all
  end
end
