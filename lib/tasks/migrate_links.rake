namespace :migrate_links do
  desc "Migrate links for a all formats"
  task all: :environment do
    Commands::V2::RepresentDownstream.new.call(
      ContentItem.where(schema_name: Presenters::MigrateExpandedLinks.schema_names)
    )
  end

  desc """
  Migrate links for a specific schema_name
  Usage
  rake 'migrate_links:schema[:schema_name]'
  """
  task :schema, [:schema_name] => :environment do |_t, args|
    schema_name = args[:schema_name]

    raise "Schema name needs to be in MigrateExpandedLinks" unless Presenters::MigrateExpandedLinks.schema_names.include?(schema_name)

    Commands::V2::RepresentDownstream.new.call(
      ContentItem.where(schema_name: schema_name)
    )
  end
end
