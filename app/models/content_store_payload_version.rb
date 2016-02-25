class ContentStorePayloadVersion < ActiveRecord::Base
  def self.increment(content_item_id)
    sql = <<-SQL
        INSERT INTO content_store_payload_versions (content_item_id)
        SELECT #{content_item_id || 'NULL'}
        WHERE NOT EXISTS(
        SELECT *
        FROM content_store_payload_versions
        WHERE content_item_id #{content_item_id_sql(content_item_id)});

        UPDATE content_store_payload_versions
        SET current = COALESCE(current, 0) + 1
        WHERE content_item_id #{content_item_id_sql(content_item_id)}
        RETURNING current;
      SQL

    ContentStorePayloadVersion.connection
      .execute(sql)
      .first["current"].to_i
  end

  def self.current_for(content_item_id)
    ContentStorePayloadVersion.find_by(content_item_id: content_item_id).current
  end

  class V1
    def self.current
      ContentStorePayloadVersion.current_for(nil)
    end

    def self.increment
      ContentStorePayloadVersion.increment(nil)
    end
  end

  def self.content_item_id_sql(content_item_id)
    content_item_id.nil? ? "IS NULL" : " = #{content_item_id}"
  end
end
