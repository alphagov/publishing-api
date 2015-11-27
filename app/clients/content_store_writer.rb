require "gds_api/content_store"
require "active_support/core_ext/hash/keys"

# This lives here and not in the GDS API adapters
# because no other application should be writing
# to the content store.
class ContentStoreWriter < GdsApi::ContentStore
  def put_content_item(base_path:, content_item:)
    put_json!(content_item_url(base_path), content_item)
  end

  def put_publish_intent(base_path:, publish_intent:)
    put_json!(publish_intent_url(base_path), publish_intent)
  end

  def get_publish_intent(base_path)
    get_json!(publish_intent_url(base_path)).to_hash.deep_symbolize_keys
  end

  def delete_publish_intent(base_path)
    delete_json!(publish_intent_url(base_path))
  end

  def delete_content_item(base_path)
    delete_json!(content_item_url(base_path))
  end

private

  def publish_intent_url(base_path)
    "#{endpoint}/publish-intent#{base_path}"
  end
end
