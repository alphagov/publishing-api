namespace :represent_downstream do
  desc "Represent all editions downstream"
  task all: :environment do
    content_ids = Document.presented.pluck(:content_id)
    Rake::Task["represent_downstream:content_id"].invoke(*content_ids)
  end

  desc "
  Represent downstream for individual or multiple document_types
  Usage
  rake 'represent_downstream:document_type[:document_types]'
  "
  task :document_type, [:document_types] => :environment do |_t, args|
    document_types = args[:document_types].split(" ")
    content_ids = Document.presented.where(editions: { document_type: document_types }).pluck(:content_id)
    Rake::Task["represent_downstream:content_id"].invoke(content_ids)
  end

  desc "
  Represent downstream for a rendering application
  Usage
  rake 'represent_downstream:rendering_app[frontend]'
  "
  task :rendering_app, [:rendering_app] => :environment do |_t, args|
    content_ids = Document.presented.where(editions: { rendering_app: args[:rendering_app] }).pluck(:content_id)
    Rake::Task["represent_downstream:content_id"].invoke(content_ids)
  end

  desc "
  Represent downstream for a publishing application
  Usage
  rake 'represent_downstream:publishing_app[frontend]'
  "
  task :publishing_app, [:publishing_app] => :environment do |_t, args|
    content_ids = Document.presented.where(editions: { publishing_app: args[:publishing_app] }).pluck(:content_id)
    Rake::Task["represent_downstream:content_id"].invoke(content_ids)
  end

  desc "
  Represent an individual or multiple documents downstream
  Usage
  rake 'represent_downstream:content_id[57a1253c-68d3-4a93-bb47-b67b9b4f6b9a]'
  "
  task content_id: :environment do |_t, args|
    content_ids = args.extras
    queue = DownstreamQueue::HIGH_QUEUE

    content_ids.uniq.each_slice(1000).each do |batch|
      Commands::V2::RepresentDownstream.new.call(batch, queue:)
      sleep 5
    end
  end

  desc "
  Represent downstream documents which were last updated in the given date
  range. The time defaults to midnight if only a date is given, so date ranges
  include the start date but exclude the end date.
  Usage
  rake 'represent_downstream:published_between[2018-01-15, 2018-01-20]'
  rake 'represent_downstream:published_between[2018-01-04T09:30:00, 2018-01-04T16:00:00]'
  "
  task :published_between, %i[start_date end_date] => :environment do |_t, args|
    content_ids = Document
      .presented
      .where(editions: { state: "published", last_edited_at: args[:start_date]..args[:end_date] })
      .pluck(:content_id)

    Rake::Task["represent_downstream:content_id"].invoke(content_ids)
  end

  namespace :high_priority do
    desc "
    Represent an individual or multiple documents downstream on the high priority
    sidekiq queue
    Usage
    rake 'represent_downstream:high_priority:content_id[57a1253c-68d3-4a93-bb47-b67b9b4f6b9a]'
    "
    task content_id: :environment do |_t, args|
      content_ids = args.extras
      queue = DownstreamQueue::HIGH_QUEUE

      content_ids.uniq.each_slice(1000).each do |batch|
        Commands::V2::RepresentDownstream.new.call(batch, queue:)
        sleep 5
      end
    end

    desc "
    Represent documents by document type(s) downstream on the high_priority sidekiq
    queue
    Usage
    rake 'represent_downstream:high_priority:document_type[NewsArticle]'
    "
    task :document_type, [:document_types] => :environment do |_t, args|
      document_types = args[:document_types].split(" ")
      content_ids = Document.presented.where(editions: { document_type: document_types }).pluck(:content_id)
      Rake::Task["represent_downstream:high_priority:content_id"].invoke(content_ids)
    end
  end
end
