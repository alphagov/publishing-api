class FixCmaCaseFirstPublishedAt < ActiveRecord::Migration[5.1]
  def change
    content_ids = Edition.joins(:document)
                         .where(publishing_app: "specialist-publisher",
                                document_type: "cma_case",
                                state: %w(draft published unpublished))
                         .where("first_published_at > (public_updated_at + interval '1 second')")
                         .pluck(:"documents.content_id")

    sql = <<-SQL.strip_heredoc
      UPDATE editions
      SET    first_published_at = (details->'metadata'->>'opened_date')::timestamp
      WHERE  publishing_app = 'specialist-publisher'
      AND    document_type  = 'cma_case'
      AND    first_published_at > (public_updated_at + interval '1 second')
      AND    (details->'metadata'->>'opened_date') != ''
      AND    (details->'metadata'->>'opened_date')::timestamp < (public_updated_at + interval '1 second')
    SQL

    ActiveRecord::Base.connection.execute(sql)

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end
  end
end
