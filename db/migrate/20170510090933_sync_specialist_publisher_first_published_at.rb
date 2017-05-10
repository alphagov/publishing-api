class SyncSpecialistPublisherFirstPublishedAt < ActiveRecord::Migration[5.0]
  def up
    sql = <<-SQL
      UPDATE editions AS e
      SET first_published_at = cn.public_timestamp
      FROM change_notes AS cn
      WHERE e.id = cn.edition_id
      AND e.publishing_app = 'specialist-publisher'
      AND e.schema_name = 'specialist_document'
      AND e.state NOT IN ('draft', 'unpublished')
      AND e.first_published_at < cn.public_timestamp
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end
end
