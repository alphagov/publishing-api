require "rails_helper"

RSpec.describe "Endpoint behaviour", type: :request do
  context "/content" do
    let(:content_item) { content_item_params }
    let(:request_body) { content_item_params.to_json }
    let(:request_path) { "/content#{base_path}" }
    let(:request_method) { :put }

    returns_200_response
    responds_with_request_body
    returns_400_on_invalid_json
    suppresses_draft_content_store_502s
    forwards_locale_extension
    accepts_root_path
    validates_path_ownership

    context "without a content id" do
      let(:request_body) {
        content_item.except(:content_id)
      }

      creates_no_derived_representations
    end
  end

  context "/draft-content" do
    let(:content_item) { content_item_params }
    let(:request_body) { content_item_params.to_json }
    let(:request_path) { "/draft-content#{base_path}" }
    let(:request_method) { :put }

    returns_200_response
    responds_with_request_body
    returns_400_on_invalid_json
    suppresses_draft_content_store_502s
    forwards_locale_extension
    accepts_root_path
    validates_path_ownership

    context "without a content id" do
      let(:request_body) {
        content_item.except(:content_id)
      }

      creates_no_derived_representations
    end
  end

  context "GET /v2/content" do
    let(:request_path) { "/v2/content?content_format=topic&fields[]=title&fields[]=description" }
    let(:request_body) { "" }
    let(:request_method) { :get }

    returns_200_response
  end

  context "PUT /v2/content/:content_id" do
    let(:content_item) { v2_content_item }
    let(:request_body) { content_item.to_json }
    let(:request_path) { "/v2/content/#{content_id}" }
    let(:request_method) { :put }

    returns_200_response
    responds_with_presented_content_item
    returns_400_on_invalid_json
    suppresses_draft_content_store_502s
    forwards_locale_extension
    accepts_root_path
    validates_path_ownership

    context "without a content id" do
      let(:request_body) {
        content_item.except(:content_id)
      }

      creates_no_derived_representations
    end
  end

  context "/v2/content/:content_id" do
    let(:content_id) { SecureRandom.uuid }
    let(:request_body) { "" }
    let(:request_path) { "/v2/content/#{content_id}" }
    let(:request_method) { :get }

    context "when the content item exists" do
      let!(:content_item) {
        FactoryGirl.create(:draft_content_item, content_id: content_id)
      }

      before do
        FactoryGirl.create(:version, target: content_item, number: 2)
      end

      returns_200_response
      responds_with_presented_content_item
      responds_with_presented_correct_locale_content_item
    end

    context "when the content item does not exist" do
      returns_404_response
    end
  end
end
