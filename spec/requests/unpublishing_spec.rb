require "rails_helper"

# This spec covers the common success case for each
# type of unpublishing.
#
# See the command spec for more detailed edge cases
# and failure modes.
#
RSpec.describe "POST /v2/content/:content_id/unpublish", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }
  let!(:content_item) {
    FactoryGirl.create(:live_content_item,
      content_id: content_id,
      base_path: base_path,
    )
  }

  describe "withdrawing" do
    let(:withdrawal_params) {
      {
        type: "withdrawal",
        explanation: "Test withdrawal",
      }.to_json
    }
    let(:withdrawal_response) {
      {
        base_path: base_path,
        content_item: a_hash_including(
          withdrawn_notice: {
            explanation: "Test withdrawal",
            withdrawn_at: Time.zone.now.iso8601,
          }
        ),
      }
    }

    it "creates an Unpublishing" do
      post "/v2/content/#{content_id}/unpublish", withdrawal_params

      expect(response.status).to eq(200), response.body

      unpublishing = Unpublishing.find_by(content_item: content_item)
      expect(unpublishing.type).to eq("withdrawal")
      expect(unpublishing.explanation).to eq("Test withdrawal")
    end

    it "sends the withdrawal information to the live content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(withdrawal_response)

        post "/v2/content/#{content_id}/unpublish", withdrawal_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "sends the withdrawal information to the draft content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(withdrawal_response)

        post "/v2/content/#{content_id}/unpublish", withdrawal_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "does not send to the message queue" do
      allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
      allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

      post "/v2/content/#{content_id}/unpublish", withdrawal_params

      expect(response.status).to eq(200), response.body
    end
  end

  describe "redirecting" do
    let(:redirect_params) {
      {
        type: "redirect",
        alternative_path: "/new-path",
      }.to_json
    }
    let(:redirect_response) {
      {
        base_path: base_path,
        content_item: {
          document_type: "redirect",
          schema_name: "redirect",
          base_path: base_path,
          publishing_app: content_item.publishing_app,
          public_updated_at: Time.zone.now.iso8601,
          redirects: [
            {
              path: base_path,
              type: "exact",
              destination: "/new-path",
            }
          ],
          payload_version: anything,
        },
      }
    }

    it "creates an Unpublishing" do
      post "/v2/content/#{content_id}/unpublish", redirect_params

      expect(response.status).to eq(200), response.body

      unpublishing = Unpublishing.find_by(content_item: content_item)
      expect(unpublishing.type).to eq("redirect")
      expect(unpublishing.alternative_path).to eq("/new-path")
    end

    it "sends a redirect to the live content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(redirect_response)

        post "/v2/content/#{content_id}/unpublish", redirect_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "sends a redirect to the draft content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(redirect_response)

        post "/v2/content/#{content_id}/unpublish", redirect_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "does not send to the message queue" do
      allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
      allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

      post "/v2/content/#{content_id}/unpublish", redirect_params

      expect(response.status).to eq(200), response.body
    end
  end

  describe "gone (remove the content)" do
    let(:gone_params) {
      {
        type: "gone",
        explanation: "Test gone",
        alternative_path: "/new-path",
      }.to_json
    }
    let(:gone_response) {
      {
        base_path: base_path,
        content_item: {
          base_path: base_path,
          document_type: "gone",
          schema_name: "gone",
          publishing_app: content_item.publishing_app,
          details: {
            explanation: "Test gone",
            alternative_path: "/new-path",
          },
          routes: [
            {
              path: base_path,
              type: "exact",
            }
          ],
          payload_version: anything,
        },
      }
    }

    it "creates an Unpublishing" do
      post "/v2/content/#{content_id}/unpublish", gone_params

      expect(response.status).to eq(200), response.body

      unpublishing = Unpublishing.find_by(content_item: content_item)
      expect(unpublishing.type).to eq("gone")
      expect(unpublishing.explanation).to eq("Test gone")
      expect(unpublishing.alternative_path).to eq("/new-path")
    end

    it "sends an unpublishing to the live content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(gone_response)

        post "/v2/content/#{content_id}/unpublish", gone_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "sends an unpublishing to the draft content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(gone_response)

        post "/v2/content/#{content_id}/unpublish", gone_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "does not send to the message queue" do
      allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
      allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

      post "/v2/content/#{content_id}/unpublish", gone_params

      expect(response.status).to eq(200), response.body
    end
  end

  describe "vanish (gone like it never existed)" do
    let(:vanish_params) {
      {
        type: "vanish",
      }.to_json
    }

    it "creates an Unpublishing" do
      post "/v2/content/#{content_id}/unpublish", vanish_params

      expect(response.status).to eq(200), response.body

      unpublishing = Unpublishing.find_by(content_item: content_item)
      expect(unpublishing.type).to eq("vanish")
    end

    it "deletes the content from the live content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:live_content_store)).to receive(:delete_content_item)
          .with(base_path)

        post "/v2/content/#{content_id}/unpublish", vanish_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "deletes the content from the draft content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
          .with(base_path)

        post "/v2/content/#{content_id}/unpublish", vanish_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "does not send to the message queue" do
      allow(PublishingAPI.service(:live_content_store)).to receive(:delete_content_item)
      allow(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

      post "/v2/content/#{content_id}/unpublish", vanish_params

      expect(response.status).to eq(200), response.body
    end
  end

  describe "a bad unpublishing type" do
    it "422s" do
      post "/v2/content/#{content_id}/unpublish", {
        type: "not-correct",
      }.to_json

      expect(response.status).to eq(422), response.body
    end
  end
end
