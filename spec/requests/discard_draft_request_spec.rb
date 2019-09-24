require "rails_helper"

RSpec.describe "Discard draft requests", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }
  let(:document) { create(:document, content_id: content_id) }
  let(:fr_document) { create(:document, content_id: content_id, locale: "fr") }

  describe "POST /v2/content/:content_id/discard-draft" do
    context "when a draft edition exists" do
      let!(:draft_edition) do
        create(:draft_edition,
               document: document,
               title: "draft",
               base_path: base_path)
      end

      it "does not send to the live content store" do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /[^-]content-store.*/)

        post "/v2/content/#{content_id}/discard-draft", params: {}.to_json

        expect(response.status).to eq(200)
      end

      it "deletes the edition from the draft content store" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
          .with(base_path)

        post "/v2/content/#{content_id}/discard-draft", params: {}.to_json

        expect(response.status).to eq(200), response.body
      end

      describe "optional locale parameter" do
        let(:french_base_path) { "/tva-tarifs" }

        let!(:french_draft_edition) do
          create(:draft_edition,
                 document: fr_document,
                 title: "draft",
                 base_path: french_base_path)
        end

        before do
          stub_request(:delete, Plek.find("draft-content-store") + "/content#{french_base_path}")
        end

        it "only deletes the French edition from the draft content store" do
          expect(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
            .with(french_base_path)

          expect(PublishingAPI.service(:draft_content_store)).not_to receive(:delete_content_item)
            .with(base_path)

          post "/v2/content/#{content_id}/discard-draft", params: { locale: "fr" }.to_json
        end
      end
    end

    context "when a draft edition does not exist" do
      it "responds with 404" do
        post "/v2/content/#{content_id}/discard-draft", params: {}.to_json

        expect(response.status).to eq(404)
      end

      it "does not send to either content store" do
        expect(WebMock).not_to have_requested(:any, /.*content-store.*/)
        expect(PublishingAPI.service(:draft_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:live_content_store)).not_to receive(:put_content_item)

        post "/v2/content/#{content_id}/discard-draft", params: {}.to_json
      end

      context "and a live edition exists" do
        before do
          create(:live_edition, document: document)
        end

        it "returns a 422" do
          post "/v2/content/#{content_id}/discard-draft", params: {}.to_json

          expect(response.status).to eq(422)
        end

        it "does not send to either content store" do
          expect(WebMock).not_to have_requested(:any, /.*content-store.*/)
          expect(PublishingAPI.service(:draft_content_store)).not_to receive(:put_content_item)
          expect(PublishingAPI.service(:live_content_store)).not_to receive(:put_content_item)

          post "/v2/content/#{content_id}/discard-draft", params: {}.to_json
        end
      end
    end
  end
end
