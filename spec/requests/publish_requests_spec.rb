require "rails_helper"

RSpec.describe "POST /v2/publish", type: :request do
  context "a draft content item exists" do
    let(:draft_content_item) { create(:draft_content_item) }
    let(:draft_content_item_attributes) { draft_content_item.attributes.deep_symbolize_keys }
    let(:expected_live_content_item_attributes) {
      draft_content_item_attributes
        .merge(draft_content_item_attributes[:metadata])
        .except(:metadata)
    }

    let(:content_id) { draft_content_item.content_id }
    let(:link_set) { create(:link_set, content_id: content_id) }
    let(:request_path) { "/v2/content/#{content_id}/publish"}
    let(:payload) {
      {
        "change_note" => "This is the change note",
        "update_type" => "major",
      }
    }
    let(:request_body) { payload.to_json }

    def do_request(body: request_body)
      post request_path, body
    end

    creates_a_content_item_representation(LiveContentItem, expected_attributes_proc: ->() { expected_live_content_item_attributes })
    logs_event("Publish", expected_payload_proc: ->{ payload.merge("content_id" => content_id) })

    it "sends item to live content store including links" do
      expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        .with(
          base_path: draft_content_item.base_path,
          content_item: hash_including("content_id" => content_id, "links" => link_set.links)
        )
      do_request
    end
  end
end
