require_relative "helpers/delete_content"

class FixOnlySupersededEditions < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    content_ids_to_delete = []

    Document
      .joins(:editions)
      .where(%q(
        NOT EXISTS (
          SELECT id FROM editions AS e
          WHERE e.state IN ('draft', 'published', 'unpublished')
            AND e.document_id = documents.id
        )
        AND editions.publishing_app IN ('service-manual-publisher', 'whitehall')
        AND editions.updated_at < '2017-01-18'
        AND editions.updated_at > '2016-02-28'
      ))
      .find_each do |document|
        edition = document.editions.order(updated_at: :desc).first
        if edition && edition.unpublishing.present?
          edition.update_column(:state, "unpublished")
        else
          content_ids_to_delete << document.content_id
          Helpers::DeleteContent.destroy_documents_with_links(document.content_id)
        end
      end

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.(content_ids_to_delete)
    end
  end
end
