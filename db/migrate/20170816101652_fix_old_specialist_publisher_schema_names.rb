class FixOldSpecialistPublisherSchemaNames < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    content_ids = editions.with_document.pluck(:content_id)

    editions.update_all(
      schema_name: "specialist_document"
    )

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end
  end

  def editions
    Edition
      .where(
        schema_name: "placeholder_specialist_document",
        content_store: %w(live draft),
      )
  end
end
