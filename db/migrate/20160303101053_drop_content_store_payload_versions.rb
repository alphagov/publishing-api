class DropContentStorePayloadVersions < ActiveRecord::Migration[4.2]
  def change
    drop_table :content_store_payload_versions
  end
end
