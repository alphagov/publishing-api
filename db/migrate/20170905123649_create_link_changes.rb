class CreateLinkChanges < ActiveRecord::Migration[5.1]
  def change
    create_table :link_changes do |t|
      t.uuid :source_content_id, null: false
      t.uuid :target_content_id, null: false
      t.string :link_type, null: false
      t.integer :change, null: false
      t.references :action, null: false

      t.timestamps
    end
  end
end
