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


    it "sends content to both content stores" do
      allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).with(anything)
      allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).with(anything)

      expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item_for_draft_content_store
            .merge(payload_version: anything)
        )

      expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item_for_live_content_store
            .merge(payload_version: anything)
        )

      put "/content#{base_path}", content_item_params.to_json

      expect(response).to be_ok, response.body
    end
  end

  context "/draft-content" do
    let(:content_item_for_draft_content_store) {
      content_item_params
        .except(:update_type)
    }

    it "sends content to the draft content store only" do
      allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).with(anything)

      expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item_for_draft_content_store
            .merge(payload_version: anything)
        )
      expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).never
      expect(WebMock).not_to have_requested(:any, /[^-]content-store.*/)

      put "/draft-content#{base_path}", content_item_params.to_json

      expect(response).to be_ok, response.body
    end
  end

  context "/v2/content" do
    let(:content_item_for_draft_content_store) {
      v2_content_item
        .except(:update_type)
        .merge(links: {})
        .merge(expanded_links: {})
    }

    it "only sends to the draft content store" do
      allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).with(anything)

      expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item_for_draft_content_store
            .merge(payload_version: anything)
        )
      expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).never
      expect(WebMock).not_to have_requested(:any, /[^-]content-store.*/)

      put "/v2/content/#{content_id}", v2_content_item.to_json

      expect(response).to be_ok, response.body
    end

    context "when a link set exists for the content item" do
      let(:link_set) do
        FactoryGirl.create(
          :link_set,
          content_id: v2_content_item[:content_id]
        )
      end

      let(:target_content_item) { create(:content_item, base_path: "/foo", title: "foo") }
      let!(:links) { create(:link, link_set: link_set, link_type: "parent", target_content_id: target_content_item.content_id) }

      let(:content_item_for_draft_content_store) do
        v2_content_item.except(:update_type).merge(
          links: Presenters::Queries::LinkSetPresenter.new(link_set).links
        ).merge(
          expanded_links: Presenters::Queries::ExpandedLinkSet.new(link_set: link_set, fallback_order: [:draft, :published]).links
        )
      end

      it "sends to the draft content store" do
        allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).with(anything)

        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_draft_content_store
              .merge(payload_version: anything)
          )

        put "/v2/content/#{content_id}", v2_content_item.to_json
        expect(response).to be_ok, response.body
      end

      it "sends the dependent changes to the draft content store" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: a_hash_including(content_id: content_id)
          )
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: "/foo",
            content_item: a_hash_including(content_id: target_content_item.content_id, title: "foo")
          )
        put "/v2/content/#{content_id}", v2_content_item.to_json
      end
    end
  end

  context "/v2/links" do
    let(:content_item) {
      v2_content_item.merge(links: links_attributes[:links])
    }
    let(:content_item_for_draft_content_store) {
      content_item
        .except(:update_type)
        .merge(access_limited: access_limit_params)
    }
    let(:content_item_for_live_content_store) {
      content_item
        .except(:access_limited, :update_type)
    }

    context "when only a draft content item exists for the link set" do
      before do
        draft = FactoryGirl.create(:draft_content_item,
          content_id: content_id,
        )

        FactoryGirl.create(:lock_version, target: draft, number: 1)

        FactoryGirl.create(:access_limit,
          users: access_limit_params.fetch(:users),
          content_item: draft,
        )
      end

      it "only sends to the draft content store" do
        allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).with(anything)

        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_draft_content_store
              .merge(payload_version: anything)
          )
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /[^-]content-store.*/)

        patch "/v2/links/#{content_id}", links_attributes.to_json

        expect(response).to be_ok, response.body
      end
    end

    context "when only a live content item exists for the link set" do
      before do
        FactoryGirl.create(:live_content_item,
          content_id: content_id,
        )
      end

      it "only sends to the live content store" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /draft-content-store.*/)
        allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).with(anything)

        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_live_content_store
              .merge(payload_version: anything)
          )

        patch "/v2/links/#{content_id}", links_attributes.to_json

        expect(response).to be_ok, response.body
      end
    end

    context "when draft and live content items exists for the link set" do
      before do
        draft = FactoryGirl.create(:draft_content_item,
          content_id: content_id,
        )

        FactoryGirl.create(:access_limit,
          users: access_limit_params.fetch(:users),
          content_item: draft,
        )

        FactoryGirl.create(:live_content_item,
          content_id: content_id,
        )
      end

      it "sends to both content stores" do
        allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).with(anything)
        allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).with(anything)

        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_draft_content_store
              .merge(payload_version: anything)
          )

        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_live_content_store
              .merge(payload_version: anything)
          )

        patch "/v2/links/#{content_id}", links_attributes.to_json

        expect(response).to be_ok, response.body
      end
    end

    context "when a content item does not exist for the link set" do
      it "does not send to either content store" do
        expect(WebMock).not_to have_requested(:any, /.*content-store.*/)
        expect(PublishingAPI.service(:draft_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:live_content_store)).not_to receive(:put_content_item)

        patch "/v2/links/#{content_id}", links_attributes.to_json

        expect(response).to be_ok, response.body
      end
    end

    context "when sending passthrough links" do
      def links_attributes
        {
          content_id: content_id,
          links: {
            organisations: [
              {
                content_id: "a-passthrough-content-id",
                title: "Some passthrough content",
              }
            ]
          }
        }
      end

      before do
        draft = FactoryGirl.create(:draft_content_item, v2_content_item.slice(*ContentItem::TOP_LEVEL_FIELDS))
        FactoryGirl.create(:lock_version, target: draft, number: 1)
        FactoryGirl.create(:access_limit, content_item: draft, users: access_limit_params.fetch(:users))
      end

      it "sends to the draft content store" do
        allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).with(anything)

        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_draft_content_store
              .merge(payload_version: anything)
              .merge(expanded_links: anything)
          )

        patch "/v2/links/#{content_id}", links_attributes.to_json

        expect(response).to be_ok, response.body
      end
    end
  end

  context "/v2/publish" do
    let(:content_id) { SecureRandom.uuid }
    let!(:draft) {
      FactoryGirl.create(:draft_content_item,
        content_id: content_id,
      )
    }

    let(:content_item_for_live_content_store) {
      draft.attributes.deep_symbolize_keys
        .merge(
          base_path: base_path,
          locale: "en",
        )
        .except(
          :id,
          :access_limited,
          :update_type,
          :metadata,
          :version,
          :old_description,
          :created_at,
          :updated_at,
          :draft_content_item_id,
          :live_content_item_id,
        )
    }

    it "sends to the live content store" do
      allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).with(anything)
      expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item_for_live_content_store
            .merge(payload_version: anything)
        )

      post "/v2/content/#{content_id}/publish", { update_type: "major" }.to_json

      expect(response).to be_ok, response.body
    end
  end
end
