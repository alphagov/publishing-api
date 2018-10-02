namespace :expanded_links do
  desc "Populate the Expanded Links table in the database"
  task populate: :environment do
    document_count = Document.count
    payload_version = Event.maximum(:id)
    Document.find_each.with_index do |document, index|
      content_id = document.content_id
      locale = document.locale

      update_links(content_id, locale, payload_version, with_drafts: true)
      update_links(content_id, locale, payload_version, with_drafts: false)

      progress(index, document_count)
    end
  end

  desc "
  Populate the Expanded Links table with content of a particular document type
  Usage
  rake 'expanded_links:populate_by_document_type[:document_type]'
  "
  task :populate_by_document_type, [:document_type] => :environment do |_t, args|
    tuples = Edition
      .with_document
      .where(document_type: args[:document_type])
      .distinct
      .pluck("documents.content_id", "documents.locale")

    payload_version = Event.maximum(:id)
    tuples.each_with_index do |(content_id, locale), index|
      update_links(content_id, locale, payload_version, with_drafts: true)
      update_links(content_id, locale, payload_version, with_drafts: false)

      progress(index, tuples.count, every: 100)
    end
  end

  desc "
  Truncate the Expanded Links table to reset the store
  Usage
  rake 'expanded_links:truncate
  "
  task truncate: :environment do
    ExpandedLinks.connection.execute("TRUNCATE expanded_links RESTART IDENTITY")
    puts "expanded_links table truncated"
  end

  def update_links(content_id, locale, payload_version, with_drafts:)
    links = Presenters::Queries::ExpandedLinkSet.by_content_id(
      content_id,
      locale: locale,
      with_drafts: with_drafts,
    ).links

    ExpandedLinks.locked_update(
      content_id: content_id,
      locale: locale,
      with_drafts: with_drafts,
      expanded_links: links,
      payload_version: payload_version,
    )
  end

  def progress(index, count, every: 1000)
    if ((index + 1) % every).zero? || (index + 1) == count
      puts "processed: #{index + 1}/#{count}"
    end
  end
end
