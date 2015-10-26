require 'rails_helper'

RSpec.describe ContentItemsController do

  let(:base_path) {
    "vat-rates"
  }

  let(:base_content_item) {
    {
      base_path: "/#{base_path}",
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
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    describe "validating the fields used for the message routing key" do
      valid_routing_keys = %w(
        word
        alpha12numeric
        under_score
        mixedCASE
      )
      invalid_routing_keys = [
        'no spaces',
        'dashed-item',
        'puncutation!',
      ]

      [
        "format",
        "update_type",
      ].each do |field|
        valid_routing_keys.each do |routing_key|
          it "should respond with 200 if #{field} has value '#{routing_key}'" do
            content_item = base_content_item.merge(field => routing_key)

            raw_json_put(
              action: :put_live_content_item,
              base_path: base_path,
              json: content_item.to_json,
            )

            expect(response.status).to eq(200)
          end
        end

        invalid_routing_keys.each do |routing_key|
          it "should respond with 422 if #{field} has value '#{routing_key}'" do
            content_item = base_content_item.merge(field => routing_key)

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
