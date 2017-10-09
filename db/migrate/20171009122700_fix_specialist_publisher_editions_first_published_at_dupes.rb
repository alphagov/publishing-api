class FixSpecialistPublisherEditionsFirstPublishedAtDupes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  # Update all the specialist-publisher editions with a
  # first_published_at date of 2016-02-29 09:24:10 where
  # this date is after the public_updated_at value
  def up
    scope = Edition.where(publishing_app: "specialist-publisher")
                   .where("first_published_at BETWEEN '2016-02-29 09:24:10' AND '2016-02-29 09:24:11'")
                   .where("first_published_at > (public_updated_at + interval '1 second')")

    document_ids = scope.where(state: %w(draft published unpublished)).distinct(:document_id).pluck(:document_id)
    content_ids = Document.where(id: document_ids).pluck(:content_id)

    count = scope.update_all("first_published_at = public_updated_at")

    puts "Updated #{count} specialist-publisher editions."

    # Represent the relevant editions downstream
    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end
  end
end
