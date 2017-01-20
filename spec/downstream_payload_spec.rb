require "rails_helper"

RSpec.describe DownstreamPayload do
  def create_web_content_item(factory, factory_options = {})
    edition = FactoryGirl.create(factory, factory_options)
    Queries::GetWebContentItems.find(edition.id)
  end

  let(:payload_version) { 1 }
  let(:state_fallback_order) { [:published] }
  subject(:downstream_payload) {
    DownstreamPayload.new(
      web_content_item,
      payload_version,
      state_fallback_order
    )
  }

  describe "#state" do
    let(:web_content_item) { create_web_content_item(:live_edition) }

    it "equals web_content_item.state" do
      expect(downstream_payload.state).to eq web_content_item.state
    end
  end

  describe "#unpublished?" do
    context "unpublished edition" do
      let(:web_content_item) { create_web_content_item(:unpublished_edition) }

      it "returns true" do
        expect(downstream_payload.unpublished?).to be true
      end
    end

    context "published edition" do
      let(:web_content_item) { create_web_content_item(:live_edition) }

      it "returns false" do
        expect(downstream_payload.unpublished?).to be false
      end
    end
  end

  describe "#content_store_action" do
    context "no base_path" do
      let(:web_content_item) { create_web_content_item(:pathless_live_edition) }

      it "returns :no_op" do
        expect(downstream_payload.content_store_action).to be :no_op
      end
    end

    context "published item" do
      let(:web_content_item) { create_web_content_item(:live_edition) }

      it "returns :put" do
        expect(downstream_payload.content_store_action).to be :put
      end
    end

    context "draft item" do
      let(:web_content_item) { create_web_content_item(:draft_edition) }

      it "returns :put" do
        expect(downstream_payload.content_store_action).to be :put
      end
    end

    context "unpublished item" do
      context "withdrawn type" do
        let(:web_content_item) { create_web_content_item(:withdrawn_unpublished_edition) }

        it "returns :put" do
          expect(downstream_payload.content_store_action).to be :put
        end
      end

      context "redirect type" do
        let(:web_content_item) { create_web_content_item(:redirect_unpublished_edition) }

        it "returns :put" do
          expect(downstream_payload.content_store_action).to be :put
        end
      end

      context "gone type" do
        let(:web_content_item) { create_web_content_item(:gone_unpublished_edition) }

        it "returns :put" do
          expect(downstream_payload.content_store_action).to be :put
        end
      end

      context "vanish type" do
        let(:web_content_item) { create_web_content_item(:vanish_unpublished_edition) }

        it "returns :delete" do
          expect(downstream_payload.content_store_action).to be :delete
        end
      end
    end
  end

  describe "#content_store_payload" do
    let(:content_store_payload_hash) {
      {
        title: web_content_item.title,
        base_path: web_content_item.base_path,
        payload_version: payload_version,
      }
    }

    context "published item" do
      let(:web_content_item) { create_web_content_item(:live_edition) }

      it "returns a content store payload" do
        expect(downstream_payload.content_store_payload).to include(content_store_payload_hash)
      end
    end

    context "draft item" do
      let(:web_content_item) { create_web_content_item(:draft_edition) }

      it "returns a content store payload" do
        expect(downstream_payload.content_store_payload).to include(content_store_payload_hash)
      end
    end

    context "unpublished item" do
      context "withdrawn type" do
        let(:web_content_item) { create_web_content_item(:withdrawn_unpublished_edition) }

        it "returns a content store payload" do
          expect(downstream_payload.content_store_payload).to include(content_store_payload_hash)
        end
      end

      context "redirect type" do
        let(:web_content_item) { create_web_content_item(:redirect_unpublished_edition) }

        it "returns a redirect payload" do
          expect(downstream_payload.content_store_payload).to include(
            document_type: "redirect",
            base_path: web_content_item.base_path,
          )
        end
      end

      context "gone type" do
        let(:web_content_item) { create_web_content_item(:gone_unpublished_edition) }

        it "returns a gone payload" do
          expect(downstream_payload.content_store_payload).to include(
            document_type: "gone",
            base_path: web_content_item.base_path,
          )
        end
      end
    end
  end

  describe "#message_queue_payload" do
    let(:web_content_item) { create_web_content_item(:live_edition) }

    it "returns a message queue payload" do
      expect(downstream_payload.message_queue_payload("major")).to include(
        base_path: web_content_item.base_path,
        title: web_content_item.title,
        update_type: "major",
        govuk_request_id: anything,
      )
    end
  end
end
