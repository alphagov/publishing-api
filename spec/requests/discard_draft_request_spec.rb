require "rails_helper"

RSpec.describe "Discard draft requests", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:request_body) { {}.to_json }
  let(:request_path) { "/v2/content/#{content_id}/discard-draft" }
  let(:request_method) { :post }

  let(:base_path) { "/vat-rates" }

  describe "POST /v2/content/:content_id/discard-draft" do
    context "when a draft content item exists" do
      let!(:draft_content_item) do
        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          title: "draft",
          base_path: base_path,
        )
      end

      returns_200_response
      does_not_send_to_live_content_store

      it "deletes the content item from the draft content store" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
          .with(base_path)

        do_request

        expect(response.status).to eq(200), response.body
      end

      describe "optional locale parameter" do
        let(:french_base_path) { "/tva-tarifs" }

        let!(:french_draft_content_item) do
          FactoryGirl.create(:draft_content_item,
            content_id: content_id,
            title: "draft",
            locale: "fr",
            base_path: french_base_path,
          )
        end

        before do
          stub_request(:delete, Plek.find('draft-content-store') + "/content#{french_base_path}")
        end

        let(:request_body) { { locale: "fr" }.to_json }

        returns_200_response
        does_not_send_to_live_content_store

        it "only deletes the French content item from the draft content store" do
          expect(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
            .with(french_base_path)

          expect(PublishingAPI.service(:draft_content_store)).not_to receive(:delete_content_item)
            .with(base_path)

          do_request
        end
      end
    end

    context "when a draft content item does not exist" do
      returns_404_response

      does_not_send_to_draft_content_store
      does_not_send_to_live_content_store

      context "and a live content item exists" do
        before do
          FactoryGirl.create(:live_content_item,
            content_id: content_id,
          )
        end

        it "returns a 422" do
          do_request

          expect(response.status).to eq(422)
        end

        does_not_send_to_draft_content_store
        does_not_send_to_live_content_store
      end
    end
  end
end
