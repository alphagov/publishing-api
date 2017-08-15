class CreateLinkables < ActiveRecord::Migration[4.2]
  def change
    create_table :linkables do |t|
      t.references :content_item, null: false
      t.string :state, null: false
      t.string :base_path, null: false
      t.string :document_type, null: false
      t.timestamps
    end

    add_index :linkables, :document_type
  end
end
