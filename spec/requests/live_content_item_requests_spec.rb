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

  describe "PUT /content" do
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
  end
end
