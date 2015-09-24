require "rails_helper"
require "govuk/client/test_helpers/url_arbiter"

RSpec.configure do |c|
  c.extend RequestHelpers
end

RSpec.describe "Publish intent requests", :type => :request do
  include GOVUK::Client::TestHelpers::URLArbiter

  let(:base_path) {
    "/vat-rates"
  }

  let(:content_item) {
    {
      publish_time: (Time.zone.now + 3.hours).iso8601,
      publishing_app: "mainstream_publisher",
      rendering_app: "frontend",
      routers: [
        {
          path: base_path,
          type: "exact",
        }
      ],
    }
  }

  before do
    stub_default_url_arbiter_responses
    stub_request(:put, %r{^content-store.*/publish-intent/.*})
  end

  describe "PUT /publish-intent" do
    check_url_registration_happens
    check_url_registration_failures
    returns_200_response
    returns_400_on_invalid_json
    suppresses_draft_content_store_502s
    accepts_root_path

    def put_content_item(body: content_item.to_json)
      put "/publish-intent#{base_path}", body
    end

    def deep_stringify_keys(hash)
      JSON.parse(hash.to_json)
    end

    let(:expected_event_payload) {
      deep_stringify_keys(content_item.merge("base_path" => base_path))
    }

    it "sends to live content store after registering the URL" do
      expect(PublishingAPI.service(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.service(:live_content_store)).to receive(:put_publish_intent)
        .with(base_path: "/vat-rates", publish_intent: content_item)
        .ordered

      put_content_item
    end

    it "does not send anything to the draft content store" do
      expect(PublishingAPI.service(:draft_content_store)).to receive(:put_publish_intent).never

      put_content_item

      expect(WebMock).not_to have_requested(:any, /draft-content-store.*/)
    end

    it "logs a 'PutPublishIntent' event in the event log" do
      put_content_item
      expect(Event.count).to eq(1)
      expect(Event.first.action).to eq('PutPublishIntent')
      expect(Event.first.user_uid).to eq(nil)
      expect(Event.first.payload).to eq(expected_event_payload)
    end
  end

  describe "GET /publish-intent/base-path" do
    it "passes the JSON through from the content store" do
      stubbed_get = stub_request(:get, %r{^content-store.*/publish-intent/vat-rates})
        .to_return(body: content_item.to_json)

      get "/publish-intent/vat-rates"

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
      expect(Event.first.action).to eq('DeletePublishIntent')
      expect(Event.first.user_uid).to eq(nil)
      expect(Event.first.payload).to eq("base_path" => "/vat-rates")
    end
  end
end
