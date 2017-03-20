class RepublishManualsDocuments < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def editions
    Edition
      .with_document
      .where(publishing_app: "manuals-publisher")
      .where.not(content_store: nil)
  end

  def content_ids_to_represent
    editions.pluck(:content_id)
  end

  def up
    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.(content_ids_to_represent)
    end
  end
end
