require "rails_helper"
require "support/shared_context/message_queue_test_mode"

RSpec.describe "POST /v2/publish", type: :request do
  include MessageQueueHelpers

  context "a draft content item exists" do
    let(:draft_content_item) { create(:draft_content_item) }
    let(:draft_content_item_attributes) { draft_content_item.attributes.deep_symbolize_keys.except(:id) }
    let(:expected_live_content_item_derived_representation) {
      draft_content_item_attributes
        .merge(draft_content_item_attributes[:metadata])
        .except(:metadata, :access_limited)
    }
    let(:expected_live_content_item_hash) {
      expected_live_content_item_derived_representation
        .deep_stringify_keys
        .merge(
          "links" => link_set.links,
        )
    }

    let(:content_id) { draft_content_item.content_id }
    let!(:link_set) { create(:link_set, content_id: content_id) }
    let(:request_path) { "/v2/content/#{content_id}/publish"}
    let(:payload) {
      {
        "update_type" => "major",
      }
    }
    let(:request_body) { payload.to_json }

    def do_request(body: request_body)
      post request_path, body
    end

    creates_a_content_item_representation(LiveContentItem, expected_attributes_proc: ->() { expected_live_content_item_derived_representation })
    logs_event("Publish", expected_payload_proc: ->{ payload.merge("content_id" => content_id) })

    it "sends item to live content store including links" do
      expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        .with(
          base_path: draft_content_item.base_path,
          content_item: expected_live_content_item_hash
        )
      do_request
    end

    describe "message queue integration" do
      include_context "using the message queue in test mode"

      it "sends the item combined with the current link set on the message queue" do
        do_request
        delivery_info, _, message_json = wait_for_message_on(@queue)
        expect(delivery_info.routing_key).to eq("#{draft_content_item.format}.#{payload['update_type']}")

        message = JSON.parse(message_json)
        expect(message).to eq(expected_live_content_item_hash.as_json.merge("update_type" => payload['update_type']))
      end
    end
  end

end
