# This spec covers the common success case for each
# type of unpublishing.
#
# See the command spec for more detailed edge cases
# and failure modes.
#
RSpec.describe "POST /v2/content/:content_id/unpublish", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }
  let!(:document) { create(:document, content_id: content_id) }
  let!(:edition) do
    create(
      :live_edition,
      document: document,
      base_path: base_path,
    )
  end

  describe "withdrawing" do
    let(:withdrawal_params) do
      {
        type: "withdrawal",
        explanation: "Test withdrawal",
      }.to_json
    end
    let(:withdrawal_response) do
      {
        base_path: base_path,
        content_item: a_hash_including(
          withdrawn_notice: {
            explanation: "Test withdrawal",
            withdrawn_at: Time.zone.now.iso8601,
          },
        ),
      }
    end

    it "creates an Unpublishing" do
      post "/v2/content/#{content_id}/unpublish", params: withdrawal_params

      expect(response.status).to eq(200), response.body

      unpublishing = Unpublishing.find_by(edition: edition)
      expect(unpublishing.type).to eq("withdrawal")
      expect(unpublishing.explanation).to eq("Test withdrawal")
    end

    it "sends the withdrawal information to the live content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(withdrawal_response)

        post "/v2/content/#{content_id}/unpublish", params: withdrawal_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "sends the withdrawal information to the draft content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(withdrawal_response)

        post "/v2/content/#{content_id}/unpublish", params: withdrawal_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "does send to the message queue" do
      allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
      allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
        .with(a_hash_including(document_type: "services_and_information"), event_type: "unpublish")

      post "/v2/content/#{content_id}/unpublish", params: withdrawal_params

      expect(response.status).to eq(200), response.body
    end
  end

  describe "redirecting" do
    let(:redirect_params_with_alternative_path) do
      {
        type: "redirect",
        alternative_path: "/new-path",
      }.to_json
    end
    let(:redirect_params_with_redirects_hash) do
      {
        type: "redirect",
        redirects: [
          {
            path: base_path,
            type: :exact,
            destination: "/new-path",
          },
        ],
      }.to_json
    end
    let(:redirect_response) do
      {
        base_path: base_path,
        content_item: {
          document_type: "redirect",
          schema_name: "redirect",
          base_path: base_path,
          locale: edition.locale,
          publishing_app: edition.publishing_app,
          public_updated_at: Time.zone.now.iso8601,
          redirects: [
            {
              path: base_path,
              type: "exact",
              destination: "/new-path",
            },
          ],
          payload_version: anything,
        },
      }
    end

    shared_examples "unpublishing with redirects" do
      it "creates an Unpublishing" do
        post "/v2/content/#{content_id}/unpublish", params: redirect_params

        expect(response.status).to eq(200), response.body

        unpublishing = Unpublishing.find_by(edition: edition)
        expect(unpublishing.type).to eq("redirect")
        expect(unpublishing.redirects).to match_array([
          a_hash_including(destination: "/new-path"),
        ])
      end

      it "sends a redirect to the live content store" do
        Timecop.freeze do
          expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
            .with(redirect_response)

          post "/v2/content/#{content_id}/unpublish", params: redirect_params

          expect(response.status).to eq(200), response.body
        end
      end

      it "sends a redirect to the draft content store" do
        Timecop.freeze do
          expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
            .with(redirect_response)

          post "/v2/content/#{content_id}/unpublish", params: redirect_params

          expect(response.status).to eq(200), response.body
        end
      end

      it "does send to the message queue" do
        allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
        expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
          .with(
            a_hash_including(
              document_type: "redirect",
              redirects: [a_hash_including(destination: "/new-path")],
            ),
            event_type: "unpublish",
          )

        post "/v2/content/#{content_id}/unpublish", params: redirect_params

        expect(response.status).to eq(200), response.body
      end
    end

    context "with a redirects hash payload" do
      let(:redirect_params) { redirect_params_with_redirects_hash }
      it_behaves_like "unpublishing with redirects"
    end

    context "with an alternative_path payload" do
      let(:redirect_params) { redirect_params_with_alternative_path }
      it_behaves_like "unpublishing with redirects"
    end
  end

  describe "gone (remove the content)" do
    let(:gone_params) do
      {
        type: "gone",
        explanation: "Test gone",
        alternative_path: "/new-path",
      }.to_json
    end
    let(:gone_response) do
      {
        base_path: base_path,
        content_item: {
          base_path: base_path,
          document_type: "gone",
          schema_name: "gone",
          locale: "en",
          publishing_app: edition.publishing_app,
          details: {
            explanation: "Test gone",
            alternative_path: "/new-path",
          },
          routes: [
            {
              path: base_path,
              type: "exact",
            },
          ],
          payload_version: anything,
          public_updated_at: anything,
        },
      }
    end

    it "creates an Unpublishing" do
      post "/v2/content/#{content_id}/unpublish", params: gone_params

      expect(response.status).to eq(200), response.body

      unpublishing = Unpublishing.find_by(edition: edition)
      expect(unpublishing.type).to eq("gone")
      expect(unpublishing.explanation).to eq("Test gone")
      expect(unpublishing.alternative_path).to eq("/new-path")
    end

    it "sends an unpublishing to the live content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(gone_response)

        post "/v2/content/#{content_id}/unpublish", params: gone_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "sends an unpublishing to the draft content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(gone_response)

        post "/v2/content/#{content_id}/unpublish", params: gone_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "does send to the message queue" do
      allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
      allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
        .with(
          a_hash_including(
            document_type: "gone",
            content_id: content_id,
            details: a_hash_including(alternative_path: "/new-path"),
          ),
          event_type: "unpublish",
        )

      post "/v2/content/#{content_id}/unpublish", params: gone_params

      expect(response.status).to eq(200), response.body
    end
  end

  describe "vanish (gone like it never existed)" do
    let(:vanish_params) do
      {
        type: "vanish",
      }.to_json
    end

    it "creates an Unpublishing" do
      post "/v2/content/#{content_id}/unpublish", params: vanish_params

      expect(response.status).to eq(200), response.body

      unpublishing = Unpublishing.find_by(edition: edition)
      expect(unpublishing.type).to eq("vanish")
    end

    it "deletes the content from the live content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:live_content_store)).to receive(:delete_content_item)
          .with(base_path)

        post "/v2/content/#{content_id}/unpublish", params: vanish_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "deletes the content from the draft content store" do
      Timecop.freeze do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
          .with(base_path)

        post "/v2/content/#{content_id}/unpublish", params: vanish_params

        expect(response.status).to eq(200), response.body
      end
    end

    it "does send to the message queue" do
      allow(PublishingAPI.service(:live_content_store)).to receive(:delete_content_item)
      allow(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
        .with(
          a_hash_including(document_type: "vanish"),
          event_type: "unpublish",
        )

      post "/v2/content/#{content_id}/unpublish", params: vanish_params

      expect(response.status).to eq(200), response.body
    end
  end

  describe "a bad unpublishing type" do
    it "422s" do
      post "/v2/content/#{content_id}/unpublish",
           params: {
             type: "not-correct",
           }.to_json

      expect(response.status).to eq(422), response.body
    end
  end
end
