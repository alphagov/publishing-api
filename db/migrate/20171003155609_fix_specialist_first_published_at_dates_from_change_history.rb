class FixSpecialistFirstPublishedAtDatesFromChangeHistory < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    document_ids = []
    statements_ary = []

    sql = <<-SQL.strip_heredoc
      SELECT e.id,
             e.document_id,
             hist->>'public_timestamp'
      FROM   editions e,
             json_array_elements(details->'change_history') hist
      WHERE  e.publishing_app = 'specialist-publisher'
      AND    e.first_published_at > (e.public_updated_at + interval '1 second')
      AND    hist IS NOT NULL
      AND    hist->>'note' = 'First published.'
      AND    (hist->>'public_timestamp')::timestamp < (e.first_published_at + interval '1 second')
    SQL

    results = ActiveRecord::Base.connection.execute(sql).values

    results.each do |edition_id, document_id, timestamp|
      statements_ary << "UPDATE editions SET first_published_at = '#{timestamp}' WHERE id = #{edition_id};"
      document_ids << document_id
    end

    statements_ary.each_slice(1000).each do |statements|
      ActiveRecord::Base.connection.execute(statements.join("\n"))
    end

    if Rails.env.production?
      content_ids = Document.where(id: document_ids.uniq).pluck(:content_id)
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end
  end
end
