class ImportLegacySpecialistPublisherFirstPublishedAtDates < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  # ~180 records match
  def up
    count = 0
    content_ids = []
    csv_data = CSV.read(Rails.root.join("db", "migrate", "data", "specialist-publisher-legacy-first-published-at.csv"))
    csv_data.each do |content_id, slug, first_published_at|
      updated = Edition.joins(:document)
                       .where(publishing_app: "specialist-publisher",
                              state: %w(draft published superseded unpublished),
                              base_path: "/#{slug}",
                              documents: { content_id: content_id })
                       .where("first_published_at > (public_updated_at + interval '1 second')")
                       .where.not(document_type: %w(finder finder_email_signup gone redirect))
                       .update_all(first_published_at: DateTime.parse(first_published_at))

      content_ids << content_id if updated > 0
      count += updated
    end

    puts "#{count} specialist-publisher editions updated."

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end
  end
end
