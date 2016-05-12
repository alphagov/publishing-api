require "rails_helper"
require "support/shared_context/message_queue_test_mode"
require "json"

RSpec.describe "Message bus", type: :request do
  include MessageQueueHelpers

  include_context "using the message queue in test mode"

  context "/content" do
    let(:request_path) { "/content#{base_path}" }

    it "places a JSON message on the queue" do
      put request_path, content_item_params.to_json

      _delivery_info, properties, _payload = wait_for_message_on(@queue)
      expect(properties[:content_type]).to eq("application/json")
    end

    context "minor update type" do
      it "uses the update type for the routing key on publish and 'links' for the link update" do
        put request_path, content_item_params.merge(update_type: "minor").to_json

        delivery_info, = wait_for_message_on(@queue)
        expect(delivery_info.routing_key).to eq("guide.links")

        delivery_info, = wait_for_message_on(@queue)
        expect(delivery_info.routing_key).to eq("guide.minor")
      end
    end

    context "detailed_guide format" do
      it "uses the format for the routing key on publish and 'links' for the link update" do
        put request_path, content_item_params.merge(format: "detailed_guide").to_json

        delivery_info, = wait_for_message_on(@queue)
        expect(delivery_info.routing_key).to eq("detailed_guide.links")

        delivery_info, = wait_for_message_on(@queue)
        expect(delivery_info.routing_key).to eq("detailed_guide.major")
      end
    end

    it "publishes a message for a redirect update" do
      put request_path, redirect_content_item.to_json

      delivery_info, = wait_for_message_on(@queue)
      expect(delivery_info.routing_key).to eq("redirect.major")
    end
  end

  context "/draft-content" do
    it "doesn't send any messages" do
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

      put "/draft-content#{base_path}", content_item_params.to_json

      expect(response.status).to eq(200)
    end
  end

  context "/v2/content" do
    it "doesn't send any messages" do
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

      put "/v2/content/#{content_id}", v2_content_item.to_json

      expect(response.status).to eq(200)
    end
  end

  context "/v2/links" do
    let(:request_body) { links_attributes.to_json }
    let(:request_path) { "/v2/links/#{content_id}" }

    context "with a live content item" do
      let!(:live_content_item) {
        create(
          :live_content_item,
          content_id: content_id,
        )
      }

      it "sends a message with a 'links' routing key" do
        Timecop.freeze do
          patch request_path, request_body

          expect(response.status).to eq(200)

          delivery_info, = wait_for_message_on(@queue)
          expect(delivery_info.routing_key).to eq("#{live_content_item.format}.links")
        end
      end
    end

    context "with a draft content item" do
      let!(:draft_content_item) {
        create(
          :draft_content_item,
          content_id: content_id,
        )
      }

      it "doesn't send any messages" do
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

        patch request_path, request_body

        expect(response.status).to eq(200)
      end
    end
  end

  context "/v2/publish" do
    before do
      create(
        :draft_content_item,
        content_id: content_id,
        format: "guide",
      )
    end

    it "sends a message with the 'format.update_type' routing key" do
      post "/v2/content/#{content_id}/publish", { update_type: "major" }.to_json

      expect(response.status).to eq(200)

      delivery_info, = wait_for_message_on(@queue)
      expect(delivery_info.routing_key).to eq("guide.major")
    end
  end
end
