class DropContentStorePayloadVersions < ActiveRecord::Migration
  def change
    drop_table :content_store_payload_versions
  end
end
