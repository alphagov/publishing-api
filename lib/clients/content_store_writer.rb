require "gds_api/base"

class ContentStoreWriter < GdsApi::Base
  def put_content_item(content_item)
    base_path = content_item[:base_path]
    put_json!("#{endpoint}/content#{base_path}", content_item)
  end
end
