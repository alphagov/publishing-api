require "rails_helper"
require "govuk/client/test_helpers/url_arbiter"

RSpec.describe "live content item requests", :type => :request do
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

  before do
    stub_default_url_arbiter_responses
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  describe "PUT /content" do
    it "registers with the URL with the URL arbiter" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).with(
        "/vat-rates",
        publishing_app: content_item[:publishing_app]
      )

      put "/content/vat-rates", content_item.to_json
    end

    it "sends to draft content store after registering the URL" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.services(:draft_content_store)).to receive(:put_content_item)
        .with(content_item).ordered

      put "/content/vat-rates", content_item.to_json
    end

    it "sends to live content store after registering the URL" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.services(:live_content_store)).to receive(:put_content_item)
        .with(content_item).ordered

      put "/content/vat-rates", content_item.to_json
    end

    it "responds with the content item as a 200" do
      put "/content/vat-rates", content_item.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(content_item.to_json)
    end

    it "returns a 400 if the JSON is invalid" do
      put "/content/vat-rates", "not a JSON"

      expect(response.status).to eq(400)
    end

    context "when the path is invalid" do
      let(:url_arbiter_response_body) {
        url_arbiter_data_for("/vat-rates",
          "errors" => {
            "path" => ["is not valid"]
          }
        ).to_json
      }

      before do
        url_arbiter_returns_validation_error_for("/vat-rates",
          "path" => ["is not valid"]
        )
      end

      it "returns a 422 with the URL arbiter's response body" do
        put "/content/vat-rates", content_item.to_json

        expect(response.status).to eq(422)
        expect(response.body).to eq(url_arbiter_response_body)
      end
    end

    context "when the path is taken" do
      let(:url_arbiter_response_body) {
        url_arbiter_data_for("/vat-rates",
          "publishing_app" => "whitehall",
          "errors" => {
            "path" => ["is already reserved by the whitehall application"]
          }
        ).to_json
      }

      before do
        url_arbiter_has_registration_for("/vat-rates", "whitehall")
      end

      it "returns a 409 with the URL arbiter's response body" do
        put "/content/vat-rates", content_item.to_json

        expect(response.status).to eq(409)
        expect(response.body).to eq(url_arbiter_response_body)
      end
    end
  end
end
