namespace :represent_downstream do
  def represent_downstream(scope)
    scope.distinct.in_batches.each do |batch|
      content_ids = batch.pluck(:content_id)
      Commands::V2::RepresentDownstream.new.call(content_ids)
      sleep 5
    end
  end

  desc "Represent all editions downstream"
  task all: :environment do
    represent_downstream(
      Edition.with_document.where.not(content_store: nil)
    )
  end

  desc "
  Represent downstream for a specific document_type
  Usage
  rake 'represent_downstream:document_type[:document_type]'
  "
  task :document_type, [:document_type] => :environment do |_t, args|
    represent_downstream(
      Edition.with_document.where(document_type: args[:document_type])
    )
  end

  desc "
  Represent downstream for a rendering application
  Usage
  rake 'represent_downstream:rendering_app[frontend]'
  "
  task :rendering_app, [:rendering_app] => :environment do |_t, args|
    represent_downstream(
      Edition.with_document.where(rendering_app: args[:rendering_app])
    )
  end

  desc "
  Represent downstream for a publishing application
  Usage
  rake 'represent_downstream:publishing_app[frontend]'
  "
  task :publishing_app, [:publishing_app] => :environment do |_t, args|
    represent_downstream(
      Edition.with_document.where(publishing_app: args[:publishing_app])
    )
  end

  desc "Represent downstream content tagged to a parent taxon"
  task tagged_to_taxon: :environment do
    represent_downstream(
      Link.joins(:link_set).where(link_type: "taxons")
    )
  end

  desc "
  Represent an individual or multiple editions downstream
  Usage
  rake 'represent_downstream:content_id[57a1253c-68d3-4a93-bb47-b67b9b4f6b9a]'
  "
  task :content_id, [:content_id] => :environment do |_t, args|
    content_ids = args[:content_id].split(" ")
    represent_downstream(
      Edition.with_document.where(documents: { content_id: content_ids })
    )
  end
end
