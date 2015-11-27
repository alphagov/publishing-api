require "rails_helper"

RSpec.describe "Discard draft requests", type: :request do
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
        )
      end

      returns_200_response
      logs_event("DiscardDraft", expected_payload_proc: -> { { content_id: "582e1d3f-690e-4115-a948-e05b3c6b3d88" } })
      does_not_send_to_live_content_store

      it "deletes the draft content item" do
        do_request

        draft = DraftContentItem.find_by(content_id: content_id)
        expect(draft).to be_nil
      end

      it "deletes the content item from the draft content store" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
          .with(base_path)

        do_request

        expect(response.status).to eq(200), response.body
      end

      context "and a live content item exists" do
        let!(:live_content_item) do
          FactoryGirl.create(:live_content_item,
            content_id: content_id,
            draft_content_item: draft_content_item,
            title: "live",
          )
        end

        let(:content_item_for_draft_content_store) do
          Presenters::ContentStorePresenter.present(live_content_item)
        end

        returns_200_response
        logs_event("DiscardDraft", expected_payload_proc: -> { { content_id: "582e1d3f-690e-4115-a948-e05b3c6b3d88" } })

        it "replaces the draft content item from the live content item" do
          do_request

          draft = DraftContentItem.find_by(content_id: content_id)
          expect(draft.title).to eq("live")
        end

        sends_to_draft_content_store
      end
    end

    context "when a draft content item does not exist" do
      returns_404_response

      does_not_log_event
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

        creates_no_derived_representations

        does_not_log_event
        does_not_send_to_draft_content_store
        does_not_send_to_live_content_store
      end
    end
  end
end
