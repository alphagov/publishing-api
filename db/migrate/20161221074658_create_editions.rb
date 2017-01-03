class CreateEditions < ActiveRecord::Migration[5.0]
  def up
    execute "UPDATE content_items SET document_id = (
               SELECT id FROM documents
               WHERE documents.content_id = content_items.content_id AND
                  documents.locale = content_items.locale
             )"

    change_column :content_items, :document_id, :integer, null: false

    remove_column :content_items, :content_id
    remove_column :content_items, :locale

    add_index :content_items, [:document_id, :state]
  end

  def down
    add_column :content_items, :content_id, :uuid
    add_column :content_items, :locale, :string

    execute "UPDATE content_items
             SET content_id = t.content_id, locale = t.locale
             FROM (SELECT id, content_id, locale FROM documents) t
             WHERE t.id = content_items.document_id"

    change_column :content_items, :content_id, :uuid, null: false
    change_column :content_items, :locale, :string, null: false
  end
end
