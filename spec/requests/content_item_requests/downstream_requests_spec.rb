require "rails_helper"

RSpec.describe "Downstream requests", type: :request do
  context "/content" do
    let(:content_item_for_draft_content_store) {
      content_item_params
        .except(:access_limited, :update_type)
    }
    let(:content_item_for_live_content_store) {
      content_item_for_draft_content_store
    }
    let(:request_body) { content_item_params.to_json }
    let(:request_path) { "/content#{base_path}" }
    let(:request_method) { :put }

    sends_to_draft_content_store
    sends_to_live_content_store
  end

  context "/draft-content" do
    let(:content_item_for_draft_content_store) {
      content_item_params
        .except(:update_type)
    }
    let(:request_body) { content_item_params.to_json }
    let(:request_path) { "/draft-content#{base_path}" }
    let(:request_method) { :put }

    sends_to_draft_content_store
    does_not_send_to_live_content_store
  end

  context "/v2/content" do
    let(:content_item_for_draft_content_store) {
      v2_content_item
        .except(:update_type)
    }
    let(:request_body) { v2_content_item.to_json }
    let(:request_path) { "/v2/content/#{content_id}" }
    let(:request_method) { :put }

    sends_to_draft_content_store
    does_not_send_to_live_content_store

    context "when a link set exists for the content item" do
      let(:link_set) do
        FactoryGirl.create(
          :link_set,
          content_id: v2_content_item[:content_id]
        )
      end

      let(:content_item_for_draft_content_store) do
        v2_content_item.except(:update_type).merge(
          links: Presenters::Queries::LinkSetPresenter.new(link_set).links
        )
      end

      sends_to_draft_content_store
    end
  end

  context "/v2/links" do
    let(:content_item) {
      v2_content_item.merge(links: links_attributes[:links])
    }
    let(:content_item_for_draft_content_store) {
      content_item
        .except(:update_type)
    }
    let(:content_item_for_live_content_store) {
      content_item
        .except(:access_limited, :update_type)
    }
    let(:request_body) { links_attributes.to_json }
    let(:request_path) { "/v2/links/#{content_id}" }
    let(:request_method) { :put }

    context "when only a draft content item exists for the link set" do
      before do
        draft = FactoryGirl.create(:draft_content_item, v2_content_item.slice(*DraftContentItem::TOP_LEVEL_FIELDS))
        FactoryGirl.create(:version, target: draft, number: 1)
      end

      sends_to_draft_content_store
      does_not_send_to_live_content_store
    end

    context "when only a live content item exists for the link set" do
      before do
        live = FactoryGirl.create(:live_content_item, v2_content_item.slice(*LiveContentItem::TOP_LEVEL_FIELDS))
        FactoryGirl.create(:version, target: live, number: 1)
      end

      does_not_send_to_draft_content_store
      sends_to_live_content_store
    end

    context "when draft and live content items exists for the link set" do
      before do
        live = FactoryGirl.create(
          :live_content_item,
          :with_draft,
          v2_content_item.slice(*LiveContentItem::TOP_LEVEL_FIELDS)
        )

        draft = live.draft_content_item

        draft.update!(access_limited: v2_content_item.fetch(:access_limited))

        FactoryGirl.create(:version, target: draft, number: 1)
        FactoryGirl.create(:version, target: live, number: 1)
      end

      sends_to_draft_content_store
      sends_to_live_content_store
    end

    context "when a content item does not exist for the link set" do
      does_not_send_to_draft_content_store
      does_not_send_to_live_content_store
    end
  end

  context "/v2/publish" do
    let(:content_id) { SecureRandom.uuid }
    let(:draft) { FactoryGirl.create(:draft_content_item, content_id: content_id) }

    let(:request_body) { { update_type: "major" }.to_json }
    let(:request_path) { "/v2/content/#{content_id}/publish" }
    let(:request_method) { :post }

    before do
      FactoryGirl.create(:version, target: draft, number: 1)
    end

    let(:content_item_for_live_content_store) {
      draft.attributes.deep_symbolize_keys
        .merge(public_updated_at: Time.zone.now.iso8601)
        .except(:id, :access_limited, :update_type, :metadata, :version)
    }

    sends_to_live_content_store
  end
end
