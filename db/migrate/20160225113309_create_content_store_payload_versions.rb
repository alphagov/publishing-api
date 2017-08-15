class CreateContentStorePayloadVersions < ActiveRecord::Migration[4.2]
  def change
    create_table :content_store_payload_versions do |t|
      t.integer :content_item_id
      t.integer :current, default: 0
    end

    add_index :content_store_payload_versions, :content_item_id, unique: true
  end
end
