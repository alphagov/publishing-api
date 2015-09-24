require "request_helper"

RSpec.describe "Derived representations", type: :request do
  context "/content" do
    let(:content_item) { content_item_without_access_limiting }
    let(:request_path) { "/content#{base_path}" }

    creates_a_link_representation
    creates_a_content_item_representation(LiveContentItem, immutable_base_path: true)
  end

  context "/draft-content" do
    let(:content_item) { content_item_with_access_limiting }
    let(:request_path) { "/draft-content#{base_path}" }

    creates_a_link_representation
    creates_a_content_item_representation(DraftContentItem, access_limited: true)
  end
end
