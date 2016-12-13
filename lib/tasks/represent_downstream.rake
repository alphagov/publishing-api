namespace :represent_downstream do
  desc "Represent all content_items downstream"
  task all: :environment do
    Commands::V2::RepresentDownstream.new.call(
      ContentItem.where("document_type != 'travel_advice'").pluck(:content_id)
    )
  end

  desc "
  Represent downstream for a specific document_type
  Usage
  rake 'represent_downstream:document_type[:document_type]'
  "
  task :document_type, [:document_type] => :environment do |_t, args|
    document_type = args[:document_type]
    content_ids = ContentItem.where(document_type: document_type).pluck(:content_id)
    Commands::V2::RepresentDownstream.new.call(content_ids)
  end

  desc "
  Represent downstream for a rendering application
  Usage
  rake 'represent_downstream:rendering_app[frontend]'
  "
  task :rendering_app, [:rendering_app] => :environment do |_t, args|
    rendering_app = args[:rendering_app]
    content_ids = ContentItem.where(rendering_app: rendering_app).pluck(:content_id)
    Commands::V2::RepresentDownstream.new.call(content_ids)
  end

  desc "
  Represent downstream for a publishing application
  Usage
  rake 'represent_downstream:publishing_app[frontend]'
  "
  task :publishing_app, [:publishing_app] => :environment do |_t, args|
    publishing_app = args[:publishing_app]
    content_ids = ContentItem.where(publishing_app: publishing_app)
    Commands::V2::RepresentDownstream.new.call(content_ids)
  end

  desc "
  Represent an individual content_item downstream
  Usage
  rake 'represent_downstream:content_id[57a1253c-68d3-4a93-bb47-b67b9b4f6b9a]'
  "
  task :content_id, [:content_id] => :environment do |_t, args|
    Commands::V2::RepresentDownstream.new.call([args[:content_id]])
  end
end
