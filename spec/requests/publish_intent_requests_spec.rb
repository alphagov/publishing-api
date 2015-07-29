require "rails_helper"
require "govuk/client/test_helpers/url_arbiter"

RSpec.configure do |c|
  c.extend RequestHelpers
end

RSpec.describe "Publish intent requests", :type => :request do
  include GOVUK::Client::TestHelpers::URLArbiter

  let(:content_item) {
    {
      publish_time: (Time.zone.now + 3.hours).iso8601,
      publishing_app: "mainstream_publisher",
      rendering_app: "frontend",
      routers: [
        {
          path: "/vat-rates",
          type: "exact",
        }
      ],
    }
  }

  before do
    stub_default_url_arbiter_responses
    stub_request(:put, %r{live-content-store.*/publish-intent/.*})
  end

  describe "PUT /publish-intent" do
    check_url_registration_happens
    check_url_registration_failures
    check_200_response
    check_400_on_invalid_json
    check_draft_content_store_502_suppression

    def put_content_item(body: content_item.to_json)
      put "/publish-intent/vat-rates", body
    end

    it "sends to live content store after registering the URL" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.services(:live_content_store)).to receive(:put_publish_intent)
        .with(base_path: "/vat-rates", publish_intent: content_item)
        .ordered

      put_content_item
    end

    it "does not send anything to the draft content store" do
      expect(PublishingAPI.services(:draft_content_store)).to receive(:put_publish_intent).never
      expect(WebMock).not_to have_requested(:any, /draft-content-store.*/)

      put_content_item
    end
  end

  describe "GET /publish-intent/base-path" do
    it "passes the JSON through from the content store" do
      stubbed_get = stub_request(:get, %r{live-content-store.*/publish-intent/vat-rates})
        .to_return(body: content_item.to_json)

      get "/publish-intent/vat-rates"

      expect(stubbed_get).to have_been_requested
      expect(response.status).to eq(200)
      expect(response.body).to eq(content_item.to_json)
    end
  end
end
