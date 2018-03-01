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
      Document.joins(:editions).where.not(editions: { content_store: nil })
    )
  end

  desc "
  Represent downstream for individual or multiple document_types
  Usage
  rake 'represent_downstream:document_type[:document_types]'
  "
  task :document_type, [:document_types] => :environment do |_t, args|
    document_types = args[:document_types].split(" ")
    represent_downstream(
      Document.joins(:editions).where(editions: { document_type: document_types })
    )
  end

  desc "
  Represent downstream for a rendering application
  Usage
  rake 'represent_downstream:rendering_app[frontend]'
  "
  task :rendering_app, [:rendering_app] => :environment do |_t, args|
    represent_downstream(
      Document.joins(:editions).where(editions: { rendering_app: args[:rendering_app] })
    )
  end

  desc "
  Represent downstream for a publishing application
  Usage
  rake 'represent_downstream:publishing_app[frontend]'
  "
  task :publishing_app, [:publishing_app] => :environment do |_t, args|
    represent_downstream(
      Document.joins(:editions).where(editions: { publishing_app: args[:publishing_app] })
    )
  end

  desc "Represent downstream content tagged to a parent taxon"
  task tagged_to_taxon: :environment do
    represent_downstream(
      Link.joins(:link_set).where(link_type: "taxons")
    )
  end

  desc "
  Represent an individual or multiple documents downstream
  Usage
  rake 'represent_downstream:content_id[57a1253c-68d3-4a93-bb47-b67b9b4f6b9a]'
  "
  task :content_id, [:content_id] => :environment do |_t, args|
    content_ids = args[:content_id].split(" ")
    represent_downstream(
      Document.where(content_id: content_ids)
    )
  end

  desc "
  Represent downstream documents which were last updated in the given date
  range. The time defaults to midnight if only a date is given, so date ranges
  include the start date but exclude the end date.
  Usage
  rake 'represent_downstream:published_between[2018-01-15, 2018-01-20]'
  rake 'represent_downstream:published_between[2018-01-04T09:30:00, 2018-01-04T16:00:00]'
  "
  task :published_between, %i(start_date end_date) => :environment do |_t, args|
    represent_downstream(
      Document.joins(:editions).where(editions: { state: "published", last_edited_at: args[:start_date]..args[:end_date] })
    )
  end
end
