require "request_helper"

RSpec.describe "Endpoint behaviour", type: :request do
  context "/content" do
    let(:content_item) { content_item_without_access_limiting }
    let(:request_path) { "/content#{base_path}" }

    returns_200_response
    returns_400_on_invalid_json
    suppresses_draft_content_store_502s
    forwards_locale_extension
    accepts_root_path
  end

  context "/draft-content" do
    let(:content_item) { content_item_with_access_limiting }
    let(:request_path) { "/draft-content#{base_path}" }

    returns_200_response
    returns_400_on_invalid_json
    suppresses_draft_content_store_502s
    forwards_locale_extension
    accepts_root_path
  end
end
