class PopulateEditionsPart2 < ActiveRecord::Migration[5.0]
  def up
    change_column :content_items, :document_id, :integer, null: false
  end

  def down
    execute "UPDATE content_items
             SET content_id = t.content_id, locale = t.locale
             FROM (SELECT id, content_id, locale FROM documents) t
             WHERE t.id = content_items.document_id"
  end
end
