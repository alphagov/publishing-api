class AddContentItemLinks < ActiveRecord::Migration
  create_table :content_item_links do |t|
    t.string :source, :null => false
    t.string :link_type
    t.string :target, :null => false
  end

  add_index :content_item_links, [:source, :target]
end
