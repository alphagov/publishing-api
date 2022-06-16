RSpec.describe "Publish intent requests", type: :request do
  let(:content_item) do
    {
      publish_time: (Time.zone.now + 3.hours).iso8601,
      publishing_app: "publisher",
      rendering_app: "frontend",
      routers: [
        {
          path: base_path,
          type: "exact",
        },
      ],
    }
  end

  before do
    stub_request(:put, %r{^content-store.*/publish-intent/.*})
  end

  describe "PUT /publish-intent" do
    it "responds with 200" do
      put "/publish-intent#{base_path}", params: content_item.to_json

      expect(response.status).to eq(200)
    end

    it "responds with a request body" do
      put "/publish-intent#{base_path}", params: content_item.to_json

      expect(response.body).to eq(content_item.to_json)
    end

    context "requested with invalid json" do
      it "returns 400" do
        put "/publish-intent#{base_path}", params: "Not JSON"

        expect(response.status).to eq(400)
      end
    end

    context "when draft content store is not running but draft 502s are suppressed" do
      before do
        @swallow_connection_errors = PublishingAPI.swallow_connection_errors
        PublishingAPI.swallow_connection_errors = true
        stub_request(:put, %r{^http://draft-content-store.*/content/.*})
          .to_return(status: 502)
      end

      it "returns the normal 200 response" do
        put "/publish-intent#{base_path}", params: content_item.to_json

        parsed_response_body = parsed_response
        expect(response.status).to eq(200)
        expect(parsed_response_body["content_id"]).to eq(content_item[:content_id])
        expect(parsed_response_body["title"]).to eq(content_item[:title])
      ensure
        PublishingAPI.swallow_connection_errors = @swallow_connection_errors
      end
    end

    context "with the root path as a base_path" do
      let(:base_path) { "/" }

      it "creates the reservation" do
        put "/publish-intent#{base_path}", params: content_item.to_json

        expect(response.status).to eq(200)
        expect(a_request(:put, %r{.*/(content|publish-intent)/$})).to have_been_made.at_least_once
      end
    end

    let(:expected_event_payload) do
      content_item.merge(base_path: base_path)
    end

    it "sends to live content store" do
      expect(PublishingAPI.service(:live_content_store)).to receive(:put_publish_intent)
        .with(base_path: "/vat-rates", publish_intent: content_item)
        .ordered

      put "/publish-intent#{base_path}", params: content_item.to_json
    end

    it "does not send anything to the draft content store" do
      expect(PublishingAPI.service(:draft_content_store)).to receive(:put_publish_intent).never

      put "/publish-intent#{base_path}", params: content_item.to_json

      expect(WebMock).not_to have_requested(:any, /draft-content-store.*/)
    end

    it "logs a 'PutPublishIntent' event in the event log" do
      put "/publish-intent#{base_path}", params: content_item.to_json

      expect(Event.count).to eq(1)
      expect(Event.first.action).to eq("PutPublishIntent")
      expect(Event.first.user_uid).to eq(nil)
      expect(Event.first.payload).to eq(expected_event_payload)
    end
  end

  describe "GET /publish-intent/base-path" do
    it "passes the JSON through from the content store" do
      stubbed_get = stub_request(:get, %r{^content-store.*/publish-intent/foo})
        .to_return(body: content_item.to_json)

      get "/publish-intent/foo"

      expect(stubbed_get).to have_been_requested
      expect(response.status).to eq(200)
      expect(response.body).to eq(content_item.to_json)
    end
  end

  describe "DELETE /publish-intent/base-path" do
    it "passes the JSON through from the content store" do
      stubbed_delete = stub_request(:delete, %r{^content-store.*/publish-intent/vat-rates})
        .to_return(body: {}.to_json)

      delete "/publish-intent/vat-rates"

      expect(stubbed_delete).to have_been_requested
      expect(response.status).to eq(200)
      expect(response.body).to eq({}.to_json)
    end

    it "logs a 'DeletePublishIntent' event in the event log" do
      stub_request(:delete, %r{^content-store.*/publish-intent/vat-rates})
        .to_return(body: {}.to_json)
      delete "/publish-intent/vat-rates"

      expect(Event.count).to eq(1)
      expect(Event.first.action).to eq("DeletePublishIntent")
      expect(Event.first.user_uid).to eq(nil)
      expect(Event.first.payload).to eq(base_path: "/vat-rates")
    end
  end
end
