namespace :migrate_links do
  desc "Migrate links for a all formats"
  task all: :environment do
    Commands::V2::RepresentDownstream.new.call(
      ContentItem.where(document_type: Presenters::MigrateExpandedLinks.document_types)
    )
  end

  desc """
  Migrate links for a specific document_type
  Usage
  rake 'migrate_links:document[:document_type]'
  """
  task :document_type, [:document_type] => :environment do |_t, args|
    document_type = args[:document_type]

    raise "document_type name needs to be in MigrateExpandedLinks" unless Presenters::MigrateExpandedLinks.document_types.include?(document_type)

    Commands::V2::RepresentDownstream.new.call(ContentItem.where(document_type: document_type))
  end
end
