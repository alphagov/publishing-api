namespace :represent_downstream do
  desc "Represent all content_items downstream"
  task all: :environment do
    Commands::V2::RepresentDownstream.new.call(
      ContentItem.where("document_type != 'travel_advice'")
    )
  end

  desc "
  Represent downstream for a specific document_type
  Usage
  rake 'represent_downstream:document_type[:document_type]'
  "
  task :document_type, [:document_type] => :environment do |_t, args|
    document_type = args[:document_type]
    Commands::V2::RepresentDownstream.new.call(ContentItem.where(document_type: document_type))
  end

  desc "
  Represent an individual content_item downstream
  Usage
  rake 'represent_downstream:content_item[57a1253c-68d3-4a93-bb47-b67b9b4f6b9a]'
  "
  task :content_item, [:content_item_id] => :environment do |_t, args|
    Commands::V2::RepresentDownstream.new.call(ContentItem.where(content_id: args[:content_item_id]))
  end
end
