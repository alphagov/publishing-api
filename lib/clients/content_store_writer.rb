require "gds_api/base"
require "active_support/core_ext/hash/keys"

class ContentStoreWriter < GdsApi::Base
  def put_content_item(base_path:, content_item:)
    put_json!("#{endpoint}/content#{base_path}", content_item)
  end

  def put_publish_intent(base_path:, publish_intent:)
    put_json!("#{endpoint}/publish-intent#{base_path}", publish_intent)
  end

  def get_publish_intent(base_path)
    get_json!("#{endpoint}/publish-intent#{base_path}").to_hash.deep_symbolize_keys
  end

  def delete_publish_intent(base_path)
    delete_json!("#{endpoint}/publish-intent#{base_path}")
  end
end
