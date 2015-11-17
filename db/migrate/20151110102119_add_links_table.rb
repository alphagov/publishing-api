class AddLinksTable < ActiveRecord::Migration
  def change
    create_table :links do |t|
      t.references :link_set, index: true, foreign_key: true
      t.string :target_content_id, null: false
      t.string :link_type, null: false

      t.timestamps null: false
    end

    add_index :links, [:link_set_id, :target_content_id]
  end
end
