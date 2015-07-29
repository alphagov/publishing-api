require "rails_helper"
require "govuk/client/test_helpers/url_arbiter"

RSpec.configure do |c|
  c.extend RequestHelpers
end

RSpec.describe "Content item requests", :type => :request do
  include GOVUK::Client::TestHelpers::URLArbiter

  let(:content_item) {
    {
      base_path: "/vat-rates",
      title: "VAT Rates",
      description: "VAT rates for goods and services",
      format: "guide",
      publishing_app: "mainstream_publisher",
      locale: "en",
      details: {
        app: "or format",
        specific: "data...",
      },
    }
  }

  let(:content_item_with_access_limiting) {
    content_item.merge(
      access_limited: {
        users: [
          "f17250b0-7540-0131-f036-005056030202",
          "74c7d700-5b4a-0131-7a8e-005056030037",
        ],
      },
    )
  }

  let(:stub_json_response) {
    double(:json_response, body: "", headers: {
      content_type: "application/json; charset=utf-8",
    })
  }

  before do
    stub_default_url_arbiter_responses
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  describe "PUT /content" do
    check_url_registration_happens
    check_url_registration_failures
    check_200_response
    check_400_on_invalid_json
    check_content_type_header
    check_draft_content_store_502_suppression

    def put_content_item(body: content_item.to_json)
      put "/content/vat-rates", body
    end

    it "sends to draft content store after registering the URL" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.services(:draft_content_store)).to receive(:put_content_item)
        .with(content_item).ordered

      put_content_item
    end

    it "sends to live content store after registering the URL" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.services(:live_content_store)).to receive(:put_content_item)
        .with(content_item)
        .and_return(stub_json_response)
        .ordered

      put_content_item
    end

    it "strips access limiting metadata from the document" do
      expect(PublishingAPI.services(:draft_content_store)).to receive(:put_content_item)
        .with(content_item)

      expect(PublishingAPI.services(:live_content_store)).to receive(:put_content_item)
        .with(content_item)
        .and_return(stub_json_response)

      put_content_item(body: content_item_with_access_limiting.to_json)
    end
  end

  describe "PUT /draft-content" do
    check_url_registration_happens
    check_url_registration_failures
    check_200_response
    check_400_on_invalid_json
    check_content_type_header
    check_draft_content_store_502_suppression

    def put_content_item(body: content_item.to_json)
      put "/draft-content/vat-rates", body
    end

    it "sends to draft content store after registering the URL" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.services(:draft_content_store)).to receive(:put_content_item)
        .with(content_item)
        .and_return(stub_json_response)
        .ordered

      put_content_item
    end

    it "does not send anything to the live content store" do
      expect(PublishingAPI.services(:live_content_store)).to receive(:put_content_item).never
      expect(WebMock).not_to have_requested(:any, /draft-content-store.*/)

      put_content_item
    end

    it "strips access limiting metadata from the document" do
      expect(PublishingAPI.services(:draft_content_store)).to receive(:put_content_item)
        .with(content_item)
        .and_return(stub_json_response)

      put_content_item(body: content_item_with_access_limiting.to_json)
    end
  end
end
