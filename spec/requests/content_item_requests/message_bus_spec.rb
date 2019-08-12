require "rails_helper"

RSpec.describe "Message bus", type: :request do
  context "/v2/content" do
    it "doesn't send any messages" do
      expect(DownstreamService).to_not receive(:broadcast_to_message_queue)
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

      put "/v2/content/#{content_id}", params: v2_content_item.to_json

      expect(response.status).to eq(200)
    end
  end

  context "/v2/links" do
    let(:request_body) { patch_links_attributes.to_json }
    let(:request_path) { "/v2/links/#{content_id}" }

    context "with a live edition" do
      before do
        create(:live_edition,
               document: create(:document, content_id: content_id),
               base_path: base_path)
      end

      it "sends a message with a 'links' routing key" do
        expect(DownstreamService).to receive(:broadcast_to_message_queue).with(anything, 'links')
        patch request_path, params: request_body

        expect(response.status).to eq(200)
      end
    end

    context "with a draft edition" do
      before do
        create(:draft_edition,
               document: create(:document, content_id: content_id),
               base_path: base_path)
      end

      it "doesn't send any messages" do
        expect(DownstreamService).to_not receive(:broadcast_to_message_queue)
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

        patch request_path, params: request_body

        expect(response.status).to eq(200)
      end
    end
  end

  context "/v2/publish" do
    before do
      create(:draft_edition,
             document: create(:document, content_id: content_id),
             document_type: "nonexistent-schema",
             schema_name: "nonexistent-schema",
             base_path: base_path)
    end

    it "sends a message with the 'document_type.update_type' routing key" do
      expect(DownstreamService).to receive(:broadcast_to_message_queue).with(anything, "major")
      post "/v2/content/#{content_id}/publish", params: { update_type: "major" }.to_json
      expect(response.status).to eq(200)
    end
  end
end
