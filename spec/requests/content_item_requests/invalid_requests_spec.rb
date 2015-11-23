require "rails_helper"

RSpec.describe "Invalid content requests", type: :request do
  let(:error_details) { { errors: { update_type: "invalid" } } }

  before do
    stub_request(:put, /publish-intent/)
      .to_return(
        status: 422,
        body: error_details.to_json,
        headers: {"Content-type" => "application/json"}
      )
  end

  context "/publish-intent" do
    let(:request_body) { content_item_params.to_json }
    let(:request_path) { "/publish-intent/#{base_path}" }
    let(:request_method) { :put }

    does_not_log_event
    creates_no_derived_representations
  end
end
