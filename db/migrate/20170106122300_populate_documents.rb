class PopulateDocuments < ActiveRecord::Migration[5.0]
  def up
    execute "INSERT INTO documents (content_id, locale)
             SELECT content_id, locale FROM content_items
               GROUP BY content_id, locale"
  end

  def down
    execute "DELETE FROM documents"
  end
end
