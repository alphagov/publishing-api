class PopulateEditionsPart2 < ActiveRecord::Migration[5.0]
  def up
    change_column :content_items, :document_id, :integer, null: false
  end

  def down
    change_column :content_items, :document_id, :integer, null: true
  end
end
