require "rails_helper"

RSpec.describe "/v2/content/:content_id/unpublish when the document is already unpublished" do
  let(:content_id) { SecureRandom.uuid }
  let(:document) do
    FactoryGirl.create(:document,
      content_id: content_id,
      locale: "en",
    )
  end

  let!(:unpublished_edition) do
    FactoryGirl.create(:unpublished_edition,
      document: document,
      base_path: "/vat-rates",
      explanation: "This explnatin has a typo",
      alternative_path: "/new-path",
    )
  end

  let(:payload) do
    {
      content_id: document.content_id,
      type: "gone",
      explanation: "This explanation is correct",
    }
  end

  context "creates an action" do
    describe Commands::V2::Unpublish do
      let(:locale) { "en" }
      let(:action_payload) { payload }
      let(:action) { "UnpublishGone" }

      include_examples "creates an action"
    end
  end

  it "maintains the state of unpublished" do
    post "/v2/content/#{content_id}/unpublish", params: payload.to_json
    expect(unpublished_edition.reload.state).to eq("unpublished")
  end

  it "updates the Unpublishing" do
    unpublishing = Unpublishing.find_by(edition: unpublished_edition)
    expect(unpublishing.explanation).to eq("This explnatin has a typo")

    post "/v2/content/#{content_id}/unpublish", params: payload.to_json

    unpublishing.reload

    expect(unpublishing.explanation).to eq("This explanation is correct")
    expect(unpublishing.alternative_path).to be_nil
  end

  it "sends an unpublishing to the draft content store" do
    expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
      .with(
        "downstream_high",
        a_hash_including(content_id: content_id)
      )

    post "/v2/content/#{content_id}/unpublish", params: payload.to_json
  end

  it "sends an unpublishing to the draft content store" do
    expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
      .with(
        "downstream_high",
        a_hash_including(content_id: content_id)
      )

    post "/v2/content/#{content_id}/unpublish", params: payload.to_json
  end

  it "sends an unpublishing to the live content store" do
    expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
      .with(
        "downstream_high",
        a_hash_including(content_id: content_id)
      )

    post "/v2/content/#{content_id}/unpublish", params: payload.to_json
  end

  context "when the unpublishing type is substitute" do
    let!(:unpublished_edition) do
      FactoryGirl.create(:substitute_unpublished_edition,
        document: document,
      )
    end

    it "rejects the request with a 404" do
      post "/v2/content/#{content_id}/unpublish", params: payload.to_json
      expect(response.status).to eq(404)
      expect(response.body).to match(/Could not find an edition to unpublish/)
    end
  end
end
