class MakeContentIdUuidType < ActiveRecord::Migration[5.0]
  def up
    change_column :content_items, :content_id, "UUID USING content_id::uuid"
    change_column :events, :content_id, "UUID USING content_id::uuid"
    change_column :link_sets, :content_id, "UUID USING content_id::uuid"
    change_column :links, :target_content_id, "UUID USING target_content_id::uuid"
  end

  def down
    change_column :content_items, :content_id, :text
    change_column :events, :content_id, :text
    change_column :link_sets, :content_id, :text
    change_column :links, :target_content_id, :text
  end
end
