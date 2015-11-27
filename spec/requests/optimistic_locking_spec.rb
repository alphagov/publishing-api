require "rails_helper"

RSpec.describe "Optimistic locking", type: :request do
  context "content endpoints" do
    let(:content_item) { v2_content_item }

    before do
      @existing_content_item = FactoryGirl.create(:draft_content_item, content_item)
      @existing_version = FactoryGirl.create(:version,
        target: @existing_content_item,
        number: 2,
      )
    end

    context "with a matching previous_version" do
      context "PUT /v2/content" do
        let(:request_path) { "/v2/content/#{content_id}" }
        let(:request_method) { :put }
        let(:request_body) {
          v2_content_item.merge(
            title: "A new title",
            previous_version: 2,
          ).to_json
        }

        it "updates the existing content item" do
          do_request

          expect(response.status).to eq(200)
          expect(@existing_content_item.reload.title).to eq("A new title")
          expect(@existing_version.reload.number).to eq(3)
          expect(WebMock).to have_requested(:put, /draft-content-store/)
        end
      end

      context "POST /v2/content/:content_id/publish" do
        let(:request_path) { "/v2/content/#{content_id}/publish" }
        let(:request_method) { :post }
        let(:request_body) {
          {
            update_type: "minor",
            previous_version: 2,
          }.to_json
        }

        it "publishes the existing content item" do
          do_request

          expect(response.status).to eq(200)
          expect(LiveContentItem.where(content_id: content_id).count).to eq(1)
          expect(WebMock).to have_requested(:put, %r{http://content-store})
        end
      end

      context "POST /v2/content/:content_id/discard-draft" do
        let(:request_path) { "/v2/content/#{content_id}/discard-draft" }
        let(:request_method) { :post }
        let(:request_body) {
          {
            previous_version: 2,
          }.to_json
        }

        it "discards the existing draft" do
          do_request

          expect(response.status).to eq(200)
          expect(DraftContentItem.where(content_id: content_id).count).to eq(0)
          expect(WebMock).to have_requested(:delete, %r{http://draft-content-store})
        end
      end
    end

    context "with a mismatched previous_version" do
      context "PUT /v2/content" do
        let(:request_path) { "/v2/content/#{content_id}" }
        let(:request_method) { :put }
        let(:request_body) {
          v2_content_item.merge(
            title: "A new title",
            previous_version: 1,
          ).to_json
        }

        it "does not update the existing content item" do
          do_request

          expect(response.status).to eq(409)
          expect(@existing_content_item.reload.title).to eq(v2_content_item[:title])
          expect(@existing_version.reload.number).to eq(2)
          expect(WebMock).not_to have_requested(:put, /draft-content-store/)
        end
      end

      context "POST /v2/content/:content_id/publish" do
        let(:request_path) { "/v2/content/#{content_id}/publish" }
        let(:request_method) { :post }
        let(:request_body) {
          {
            update_type: "minor",
            previous_version: 1,
          }.to_json
        }

        it "does not publish the existing content item" do
          do_request

          expect(response.status).to eq(409)
          expect(LiveContentItem.where(content_id: content_id).count).to eq(0)
          expect(WebMock).not_to have_requested(:put, %r{http://content-store})
        end
      end

      context "POST /v2/content/:content_id/discard-draft" do
        let(:request_path) { "/v2/content/#{content_id}/discard-draft" }
        let(:request_method) { :post }
        let(:request_body) {
          {
            previous_version: 1,
          }.to_json
        }

        it "does not discard the existing draft" do
          do_request

          expect(response.status).to eq(409)
          expect(DraftContentItem.where(content_id: content_id).count).to eq(1)
          expect(WebMock).not_to have_requested(:delete, %r{http://draft-content-store})
        end
      end
    end
  end

  context "PUT /v2/links" do
    let(:request_path) { "/v2/links/#{content_id}" }
    let(:request_method) { :put }

    context "when a draft content item exists without a live item" do
      before do
        draft = FactoryGirl.create(:draft_content_item, content_id: content_id)
        FactoryGirl.create(:version, target: draft)
        existing_link_set = FactoryGirl.create(:link_set,
          content_id: "582e1d3f-690e-4115-a948-e05b3c6b3d88"
        )
        FactoryGirl.create(:link,
          link_set: existing_link_set,
          target_content_id: "bf3e4b4f-f02d-4658-95a7-df7c74cd0f50"
        )
        @existing_version = FactoryGirl.create(
          :version,
          target: existing_link_set,
          number: 2,
        )
      end

      context "with a matching previous_version" do
        let(:request_body) {
          links_attributes.merge(
            previous_version: 2,
          ).to_json
        }

        it "updates the link set" do
          do_request

          expect(response.status).to eq(200)
          expect(@existing_version.reload.number).to eq(3)
          expect(WebMock).to have_requested(:put, /draft-content-store/)
        end
      end

      context "with a mismatched previous_version" do
        let(:request_body) {
          links_attributes.merge(
            previous_version: 1,
          ).to_json
        }

        it "does not update the link set" do
          do_request

          expect(response.status).to eq(409)
          expect(@existing_version.reload.number).to eq(2)
          expect(WebMock).not_to have_requested(:put, /draft-content-store/)
        end
      end
    end

    context "when a live content item exists without a draft item" do
      before do
        live = FactoryGirl.create(:live_content_item, content_id: content_id)
        FactoryGirl.create(:version, target: live)
        existing_link_set = FactoryGirl.create(:link_set,
          content_id: "582e1d3f-690e-4115-a948-e05b3c6b3d88"
        )
        FactoryGirl.create(:link,
          link_set: existing_link_set,
          target_content_id: "bf3e4b4f-f02d-4658-95a7-df7c74cd0f50"
        )
        @existing_version = FactoryGirl.create(
          :version,
          target: existing_link_set,
          number: 2,
        )
      end

      context "with a matching previous_version" do
        let(:request_body) {
          links_attributes.merge(
            previous_version: 2,
          ).to_json
        }

        it "updates the link set" do
          do_request

          expect(response.status).to eq(200)
          expect(@existing_version.reload.number).to eq(3)
          expect(WebMock).to have_requested(:put, %r{http://content-store})
        end
      end

      context "with a mismatched previous_version" do
        let(:request_body) {
          links_attributes.merge(
            previous_version: 1,
          ).to_json
        }

        it "does not update the link set" do
          do_request

          expect(response.status).to eq(409)
          expect(@existing_version.reload.number).to eq(2)
          expect(WebMock).not_to have_requested(:put, %r{http://content-store})
        end
      end
    end

    context "when both a draft and live content item exist" do
      before do
        live = FactoryGirl.create(:live_content_item, :with_draft, content_id: content_id)
        draft = live.draft_content_item

        FactoryGirl.create(:version, target: live)
        FactoryGirl.create(:version, target: draft)
        existing_link_set = FactoryGirl.create(:link_set,
          content_id: "582e1d3f-690e-4115-a948-e05b3c6b3d88"
        )
        FactoryGirl.create(:link,
          link_set: existing_link_set,
          target_content_id: "bf3e4b4f-f02d-4658-95a7-df7c74cd0f50"
        )
        @existing_version = FactoryGirl.create(:version,
          target: existing_link_set,
          number: 2,
        )
      end

      context "with a matching previous_version" do
        let(:request_body) {
          links_attributes.merge(
            previous_version: 2,
          ).to_json
        }

        it "updates the link set" do
          do_request

          expect(response.status).to eq(200)
          expect(@existing_version.reload.number).to eq(3)
          expect(WebMock).to have_requested(:put, /draft-content-store/)
          expect(WebMock).to have_requested(:put, %r{http://content-store})
        end
      end

      context "with a mismatched previous_version" do
        let(:request_body) {
          links_attributes.merge(
            previous_version: 1,
          ).to_json
        }

        it "does not update the link set" do
          do_request

          expect(response.status).to eq(409)
          expect(@existing_version.reload.number).to eq(2)
          expect(WebMock).not_to have_requested(:put, /draft-content-store/)
          expect(WebMock).not_to have_requested(:put, %r{http://content-store})
        end
      end
    end
  end
end
