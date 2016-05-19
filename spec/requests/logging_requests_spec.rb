require "rails_helper"
require "sidekiq/testing"

RSpec.describe "Logging requests", type: :request do
  let(:govuk_request_id) { "12345-67890" }

  it "adds a request uuid to the content store worker job" do
    Sidekiq::Testing.fake! do
      put("/v2/content/#{SecureRandom.uuid}", content_item_params.except(:links).to_json,
        "HTTP_GOVUK_REQUEST_ID" => govuk_request_id,
      )
      GdsApi::GovukHeaders.clear_headers # Simulate workers running in a separate thread
      Sidekiq::Worker.drain_all # Run all workers
      Sidekiq::Worker.clear_all
    end

    expect(WebMock).to have_requested(:put, /draft-content-store.*content/)
      .with(headers: {
        "GOVUK-Request-Id" => govuk_request_id,
      })
  end

  it "adds a request uuid to the message bus" do
    draft_content_item = FactoryGirl.create(:draft_content_item, base_path: base_path)

    expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
      .with(hash_including(govuk_request_id: govuk_request_id))

    post("/v2/content/#{draft_content_item.content_id}/publish", { update_type: "minor" }.to_json,
      "HTTP_GOVUK_REQUEST_ID" => "12345-67890"
    )
  end
end
