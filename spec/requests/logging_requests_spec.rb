require "rails_helper"
require "sidekiq/testing"

RSpec.describe "Logging requests", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:draft_content_item_params) { content_item_params.except(:links) }

  around do |example|
    Sidekiq::Testing.fake! do
      example.run
      Sidekiq::Worker.clear_all
    end
  end

  it "adds a request uuid to the content store worker job" do
    put("/v2/content/#{content_id}", draft_content_item_params.to_json,
      "HTTP_GOVUK_REQUEST_ID" => "12345-67890"
    )
    GdsApi::GovukHeaders.clear_headers # Simulate workers running in a separate thread
    Sidekiq::Worker.drain_all # Run all workers

    expect(WebMock).to have_requested(:put, /draft-content-store.*content/)
      .with(headers: {
        "GOVUK-Request-Id" => "12345-67890"
      })
  end
end
