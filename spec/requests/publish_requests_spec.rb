require "rails_helper"
require "support/shared_context/message_queue_test_mode"

RSpec.describe "POST /v2/publish", type: :request do
  include MessageQueueHelpers

  let(:draft_content_item_attributes) { draft_content_item.attributes.deep_symbolize_keys.except(:id, :version) }
  let(:expected_live_content_item_derived_representation) {
    draft_content_item_attributes
      .merge(draft_content_item_attributes[:metadata])
      .merge(public_updated_at: draft_content_item_attributes[:public_updated_at].iso8601)
      .except(:metadata, :access_limited)
  }
  let(:expected_live_content_item_hash) {
    expected_live_content_item_derived_representation
      .deep_symbolize_keys
      .merge(
        links: link_set.links,
      )
  }

  let(:content_id) { draft_content_item.content_id }
  let!(:link_set) { create(:link_set, content_id: content_id) }
  let(:request_path) { "/v2/content/#{content_id}/publish"}
  let(:payload) {
    {
      update_type: "major",
    }
  }
  let(:request_body) { payload.to_json }

  def do_request(body: request_body, headers: {})
    post request_path, body, headers
  end

  context "a draft content item exists with version 1" do
    let(:draft_content_item) { FactoryGirl.create(:draft_content_item, version: 1) }

    logs_event("Publish", expected_payload_proc: ->{ payload.merge(content_id: content_id) })

    it "creates the LiveContentItem derived representation" do
      do_request

      expect(LiveContentItem.count).to eq(1)

      item = LiveContentItem.first

      expect(item.base_path).to eq(base_path)
      expect(item.content_id).to eq(expected_live_content_item_derived_representation[:content_id])
      expect(item.details).to eq(expected_live_content_item_derived_representation[:details].deep_symbolize_keys)
      expect(item.format).to eq(expected_live_content_item_derived_representation[:format])
      expect(item.locale).to eq(expected_live_content_item_derived_representation[:locale])
      expect(item.publishing_app).to eq(expected_live_content_item_derived_representation[:publishing_app])
      expect(item.rendering_app).to eq(expected_live_content_item_derived_representation[:rendering_app])
      expect(item.public_updated_at).to eq(expected_live_content_item_derived_representation[:public_updated_at])
      expect(item.description).to eq(expected_live_content_item_derived_representation[:description])
      expect(item.title).to eq(expected_live_content_item_derived_representation[:title])
      expect(item.routes).to eq(expected_live_content_item_derived_representation[:routes].map(&:deep_symbolize_keys))
      expect(item.redirects).to eq(expected_live_content_item_derived_representation[:redirects].map(&:deep_symbolize_keys))
      expect(item.metadata[:need_ids]).to eq(expected_live_content_item_derived_representation[:need_ids])
      expect(item.metadata[:phase]).to eq(expected_live_content_item_derived_representation[:phase])
    end

    it "gives the new LiveContentItem the same version number as the draft item" do
      do_request

      expect(LiveContentItem.first.version).to eq(draft_content_item.version)
    end
  end

  context "a draft content item exists with version 2" do
    let(:draft_content_item) { create(:draft_content_item, version: 2) }

    context "a LiveContentItem exists with version 1" do
      before do
        LiveContentItem.create(
          title: "An existing title",
          content_id: expected_live_content_item_derived_representation[:content_id],
          locale: expected_live_content_item_derived_representation[:locale],
          details: expected_live_content_item_derived_representation[:details],
          metadata: {},
          base_path: base_path,
          version: 1
        )
      end

      it "updates the existing LiveContentItem" do
        do_request

        expect(LiveContentItem.count).to eq(1)
        expect(LiveContentItem.last.title).to eq(expected_live_content_item_derived_representation[:title])
      end

      it "gives the updated LiveContentItem the same version number as the draft item" do
        do_request

        expect(LiveContentItem.first.version).to eq(draft_content_item.version)
      end
    end

    context "the draft content item is already published" do
      let!(:live_content_item) { FactoryGirl.create(:live_content_item) }
      let!(:draft_content_item) { live_content_item.draft_content_item }

      it "reports an error" do
        expect(live_content_item.version).to eq(draft_content_item.version)

        do_request

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)).to match("error" => hash_including("message" => /already published/))
      end
    end

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
        expect(delivery_info.routing_key).to eq("#{draft_content_item.format}.#{payload[:update_type]}")

        message = JSON.parse(message_json)
        expect(message).to eq(expected_live_content_item_hash.as_json.merge("update_type" => payload[:update_type]))
      end
    end

    context "update_type is absent" do
      let(:payload) { {} }

      it "reports an error" do
        do_request

        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)).to match("error" => hash_including("fields" => {"update_type" => ["is required"]}))
      end
    end
  end
end
