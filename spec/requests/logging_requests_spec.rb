require "rails_helper"

RSpec.describe "Logging requests", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:draft_content_item_params) { content_item_params.except(:links) }

  it "adds a govuk request uuid header" do
    put "/v2/content/#{content_id}", draft_content_item_params.to_json
    expect(GdsApi::GovukHeaders.headers).to include(:x_govuk_request_uuid)
  end

  it "adds a request uuid to the content store worker job" do
    allow_any_instance_of(ActionDispatch::Request)
      .to receive(:uuid).and_return("12345-67890")

    expect(ContentStoreWorker).to receive(:perform_in)
      .with(
        2.second,
        content_store: Adapters::DraftContentStore,
        content_item_id: anything,
        request_uuid: "12345-67890",
      )

    put "/v2/content/#{content_id}", draft_content_item_params.to_json
  end
end
