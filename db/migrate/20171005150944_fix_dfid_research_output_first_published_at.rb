class FixDfidResearchOutputFirstPublishedAt < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  # There are ~63000 editions which have a first_published_at timestamp
  # later than their public_updated_at timestamp. So use legacy data from
  # metadata to fix this.
  #
  def up
    content_ids = Edition.joins(:document)
                         .where(publishing_app: "specialist_publisher",
                                document_type: "dfid_research_output",
                                state: %w(draft published unpublished))
                         .where("first_published_at > (public_updated_at + interval '1 second')")
                         .pluck(:"documents.content_id")

    sql = <<-SQL.strip_heredoc
      UPDATE editions
      SET    first_published_at = (details->'metadata'->>'first_published_at')::timestamp
      WHERE  publishing_app = 'specialist-publisher'
      AND    document_type  = 'dfid_research_output'
      AND    first_published_at > (public_updated_at + interval '1 second')
      AND    (details->'metadata'->>'first_published_at')::timestamp < (public_updated_at + interval '1 second')
    SQL

    ActiveRecord::Base.connection.execute(sql)

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end
  end
end
