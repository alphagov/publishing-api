class FixRemainingSpecialistPublisherFirstPublishedAtDates < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    scope = Edition.where(publishing_app: "specialist-publisher")
                   .where.not(document_type: %w(finder finder_email_signup gone redirect))
                   .where("first_published_at > (public_updated_at + interval '1 second')")

    content_ids = scope.joins(:document).pluck(:content_id)

    count = scope.update_all("first_published_at = public_updated_at")

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end

    puts "Updated #{count} specialist-publisher editions."
  end
end
