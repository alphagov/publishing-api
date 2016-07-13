namespace :represent_downstream do
  desc "Represent all content_items downstream"
  task all: :environment do
    Commands::V2::RepresentDownstream.new.call(
      ContentItem.where("document_type != 'travel_advice'")
    )
  end

  desc """
  Represent downstream for a specific document_type
  Usage
  rake 'represent_downstream:document_type[:document_type]'
  """
  task :document_type, [:document_type] => :environment do |_t, args|
    document_type = args[:document_type]
    raise "Can't migrate travel_advice yet" if document_type == "travel_advice"
    Commands::V2::RepresentDownstream.new.call(ContentItem.where(document_type: document_type))
  end
end
