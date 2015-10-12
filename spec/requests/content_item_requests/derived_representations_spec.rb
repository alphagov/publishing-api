require "rails_helper"

RSpec.describe "Derived representations", type: :request do
  context "/content" do
    let(:request_body) { content_item_without_access_limiting.to_json }
    let(:request_path) { "/content#{base_path}" }
    let(:request_method) { :put }

    creates_a_link_representation(expected_attributes: RequestHelpers::Mocks.links_attributes)
    creates_a_content_item_representation(LiveContentItem, expected_attributes_proc: -> { content_item_without_access_limiting })
    allows_base_path_to_be_changed(LiveContentItem)
  end

  context "/draft-content" do
    let(:request_body) { content_item_with_access_limiting.to_json }
    let(:request_path) { "/draft-content#{base_path}" }
    let(:request_method) { :put }

    creates_a_link_representation(expected_attributes: RequestHelpers::Mocks.links_attributes)
    creates_a_content_item_representation(DraftContentItem, expected_attributes_proc: -> { content_item_with_access_limiting }, access_limited: true)
    allows_base_path_to_be_changed(DraftContentItem)
  end

  context "/v2/content" do
    let(:request_body) { v2_content_item.to_json }
    let(:request_path) { "/v2/content/#{content_id}" }
    let(:request_method) { :put }

    creates_a_content_item_representation(DraftContentItem, expected_attributes_proc: -> { v2_content_item }, access_limited: true)
  end

  context "/v2/links" do
    let(:request_body) { links_attributes.to_json }
    let(:request_path) { "/v2/links/#{content_id}" }
    let(:request_method) { :put }

    creates_a_link_representation(expected_attributes: RequestHelpers::Mocks.links_attributes)
  end
end
