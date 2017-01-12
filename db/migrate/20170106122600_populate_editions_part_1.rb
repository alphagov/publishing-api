class PopulateEditionsPart1 < ActiveRecord::Migration[5.0]
  def up
    execute "UPDATE content_items SET document_id = (
               SELECT id FROM documents
               WHERE documents.content_id = content_items.content_id AND
                  documents.locale = content_items.locale
             )"
  end

  def down
    change_column :content_items, :content_id, :uuid, null: false
    change_column :content_items, :locale, :string, null: false
  end
end
