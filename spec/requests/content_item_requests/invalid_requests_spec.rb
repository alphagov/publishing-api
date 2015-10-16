require "rails_helper"

RSpec.describe "Invalid content requests", type: :request do
  let(:error_details) { {errors: {update_type: "invalid"}} }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
      .to_return(
        status: 422,
        body: error_details.to_json,
        headers: {"Content-type" => "application/json"}
      )
  end

  context "/content" do
    let(:request_body) { content_item_without_access_limiting.to_json }
    let(:request_path) { "/content#{base_path}" }
    let(:request_method) { :put }

    does_not_log_event
    creates_no_derived_representations
  end

  context "/draft-content" do
    let(:request_body) { content_item_with_access_limiting.to_json }
    let(:request_path) { "/draft-content#{base_path}" }
    let(:request_method) { :put }

    does_not_log_event
    creates_no_derived_representations
  end

  context "/v2/content" do
    let(:request_body) { v2_content_item.to_json }
    let(:request_path) { "/v2/content/#{content_id}" }
    let(:request_method) { :put }

    does_not_log_event
    creates_no_derived_representations
  end

  context "/v2/links" do
    let(:request_body) { links_attributes.to_json }
    let(:request_path) { "/v2/links/#{content_id}" }
    let(:request_method) { :put }

    before do
      FactoryGirl.create(:live_content_item, v2_content_item.slice(*LiveContentItem::TOP_LEVEL_FIELDS))
      DraftContentItem.last.update!(access_limited: v2_content_item.fetch(:access_limited))
    end

    does_not_log_event
    creates_no_derived_representations
  end
end
