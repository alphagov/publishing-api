require 'rails_helper'
require "govuk/client/test_helpers/url_arbiter"

RSpec.describe ContentItemsController do
  include GOVUK::Client::TestHelpers::URLArbiter

  let(:base_path) {
    "/vat-rates"
  }

  let(:base_content_item) {
    {
      base_path: base_path,
      title: "VAT rates",
      description: "VAT rates for goods and services",
      format: "guide",
      need_ids: ["100123", "100124"],
      public_updated_at: "2014-05-14T13:00:06Z",
      publishing_app: "mainstream_publisher",
      rendering_app: "mainstream_frontend",
      locale: "en",
      details: {
        body: "<p>Soemthing about VAT</p>\n",
      },
      routes: [
        {
          path: "/vat-rates",
          type: "exact",
        }
      ],
      update_type: "major",
    }
  }

  describe 'put_live_content_item' do
    before do
      stub_default_url_arbiter_responses
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    describe "validating the fields used for the message routing key" do
      [
        "format",
        "update_type",
      ].each do |field|
        it "requires #{field} to be suitable as a routing_key" do
          %w(
            word
            alpha12numeric
            under_score
            mixedCASE
          ).each do |value|
            content_item = base_content_item.merge(field => value)

            raw_json_put(
              action: :put_live_content_item,
              base_path: base_path,
              json: content_item.to_json,
            )

            expect(response.status).to eq(200)
          end

          [
            'no spaces',
            'dashed-item',
            'puncutation!',
          ].each do |value|
            content_item = base_content_item.merge(field => value)

            raw_json_put(
              action: :put_live_content_item,
              base_path: base_path,
              json: content_item.to_json,
            )

            expect(response.status).to eq(422)
          end
        end
      end
    end
  end

  def raw_json_put(action:, base_path:, json:)
    request.env["RAW_POST_DATA"] = json
    put action, base_path: base_path
  end
end
