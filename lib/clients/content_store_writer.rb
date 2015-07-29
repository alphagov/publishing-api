require "gds_api/base"

class ContentStoreWriter < GdsApi::Base
  def put_content_item(content_item)
    base_path = content_item[:base_path]
    put_json!("#{endpoint}/content#{base_path}", content_item)
  end

  def put_publish_intent(base_path:, publish_intent:)
    put_json!("#{endpoint}/publish-intent#{base_path}", publish_intent)
  end
end
