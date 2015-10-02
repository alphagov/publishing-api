require "rails_helper"

RSpec.describe "Derived representations", type: :request do
  context "/content" do
    let(:request_body) { content_item_without_access_limiting.to_json }
    let(:request_path) { "/content#{base_path}" }

    creates_a_link_representation(expected_attributes: RequestHelpers::Mocks.links_attributes)
    creates_a_content_item_representation(LiveContentItem, expected_attributes: RequestHelpers::Mocks.content_item_without_access_limiting, immutable_base_path: true)
  end

  context "/draft-content" do
    let(:request_body) { content_item_with_access_limiting.to_json }
    let(:request_path) { "/draft-content#{base_path}" }

    creates_a_link_representation(expected_attributes: RequestHelpers::Mocks.links_attributes)
    creates_a_content_item_representation(DraftContentItem, expected_attributes: RequestHelpers::Mocks.content_item_with_access_limiting, access_limited: true)
  end
end
