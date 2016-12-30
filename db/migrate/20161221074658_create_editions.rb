class CreateEditions < ActiveRecord::Migration[5.0]
  def up
    execute 'UPDATE content_items SET document_id = (
               SELECT id FROM documents
               WHERE documents.content_id = content_items.content_id AND
                  documents.locale = content_items.locale
             )'

    change_column :content_items, :document_id, :integer, null: false

    remove_column :content_items, :content_id
    remove_column :content_items, :locale

    add_index :content_items, [:document_id, :state]
  end

  def down
    add_column :content_items, :content_id, :string, null: false
    add_column :content_items, :locale, :string, null: false

    execute 'UPDATE content_items
             SET content_id = t.content_id, locale = t.locale
             FROM (SELECT id, content_id, locale FROM documents) t
             WHERE t.id = content_items.document_id'
  end
end
