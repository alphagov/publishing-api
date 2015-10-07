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

    it "does not log an event in the event log" do
      do_request

      expect(Event.count).to eq(0)
      expect(response.status).to eq(422)
      expect(response.body).to eq(error_details.to_json)
    end

    creates_no_derived_representations
  end

  context "/draft-content" do
    let(:request_body) { content_item_with_access_limiting.to_json }
    let(:request_path) { "/draft-content#{base_path}" }

    it "does not log an event in the event log" do
      do_request

      expect(Event.count).to eq(0)
      expect(response.status).to eq(422)
      expect(response.body).to eq(error_details.to_json)
    end

    creates_no_derived_representations
  end

  context "/v2/content" do
    let(:request_body) { v2_content_item.to_json }
    let(:request_path) { "/v2/content/#{content_id}" }

    it "does not log an event in the event log" do
      do_request

      expect(Event.count).to eq(0)
      expect(response.status).to eq(422)
      expect(response.body).to eq(error_details.to_json)
    end

    creates_no_derived_representations
  end
end
