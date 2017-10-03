class FixCmaCaseFirstPublishedAt < ActiveRecord::Migration[5.1]
  def change
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
  end
end
