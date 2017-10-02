class FixCmaCaseFirstPublishedAt < ActiveRecord::Migration[5.1]
  def change
    # The content_ids for the items that will need representing downstream
    content_ids = Edition.joins(:document)
                         .where(publishing_app: "specialist-publisher",
                                document_type: "cma_case",
                                state: %w(draft published unpublished))
                         .where("first_published_at > (public_updated_at + interval '1 second')")
                         .pluck(:"documents.content_id")

    # Update the items which have an opened date
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

    # Update the remaining items with the public_updated_at value
    sql = <<-SQL.strip_heredoc
      UPDATE editions
      SET    first_published_at = public_updated_at
      WHERE  publishing_app = 'specialist-publisher'
      AND    document_type  = 'cma_case'
      AND    first_published_at > (public_updated_at + interval '1 second')
    SQL

    ActiveRecord::Base.connection.execute(sql)

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end
  end
end
