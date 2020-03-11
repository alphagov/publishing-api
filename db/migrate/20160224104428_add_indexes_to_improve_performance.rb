class AddIndexesToImprovePerformance < ActiveRecord::Migration[4.2]
  def change
    add_index :content_items, :content_id
    add_index :content_items, :format
    add_index :content_items, :publishing_app
    add_index :content_items, :rendering_app
    add_index :links, :link_type
    add_index :lock_versions, %i[target_id target_type]
    add_index :locations, :base_path
  end
end
