class UpdateChangeNotes < ActiveRecord::Migration[5.0]
  def change
    change_table :change_notes do |t|
      t.string :content_id
      t.index :content_id
      t.change :content_item_id, :integer, null: true
    end
  end
end
