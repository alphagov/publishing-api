require "rails_helper"

RSpec.describe "Logging requests", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:draft_content_item_params) { content_item_params.except(:links) }

  it "adds a request uuid to the content store worker job" do
    expect(PresentedContentStoreWorker).to receive(:perform_async)
      .with(
        content_store: Adapters::DraftContentStore,
        payload: anything,
        request_uuid: "12345-67890",
      )

    put("/v2/content/#{content_id}", draft_content_item_params.to_json,
      "HTTP_GOVUK_REQUEST_ID" => "12345-67890"
    )
  end
end
