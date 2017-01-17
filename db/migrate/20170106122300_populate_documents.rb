class PopulateDocuments < ActiveRecord::Migration[5.0]
  def up
    execute "INSERT INTO documents (content_id, locale)
             SELECT content_id, locale FROM content_items
             WHERE NOT EXISTS (
               SELECT 1 FROM documents
               WHERE documents.content_id = content_items.content_id AND documents.locale = content_items.locale
             )
             GROUP BY content_id, locale"
  end
end
