require "rails_helper"

RSpec.describe "Downstream requests", type: :request do
  context "/v2/content" do
    let(:content_item_for_draft_content_store) {
      v2_content_item
        .except(:update_type)
        .merge(expanded_links: {
          available_translations: available_translations
        })
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

      put "/v2/content/#{content_id}", params: v2_content_item.to_json

      expect(response).to be_ok, response.body
    end

    context "when a link set exists for the content item" do
      let(:link_set) do
        FactoryGirl.create(:link_set,
          content_id: v2_content_item[:content_id]
        )
      end

      let(:target_content_item) { FactoryGirl.create(:content_item, base_path: "/foo", title: "foo") }
      let!(:links) { FactoryGirl.create(:link, link_set: link_set, link_type: "parent", target_content_id: target_content_item.content_id) }

      let(:content_item_for_draft_content_store) do
        v2_content_item.except(:update_type).merge(
          expanded_links: Presenters::Queries::ExpandedLinkSet.new(content_id: link_set.content_id, state_fallback_order: [:draft, :published]).links
        )
      end

      it "sends to the draft content store" do
        allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).with(anything)

        put "/v2/content/#{content_id}", params: v2_content_item.to_json
        expect(PublishingAPI.service(:draft_content_store)).to have_received(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_draft_content_store
              .merge(payload_version: anything)
          )

        expect(response).to be_ok, response.body
      end
    end
  end

  context "/v2/links" do
    let(:content_item) { v2_content_item }

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
          base_path: base_path,
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

        patch "/v2/links/#{content_id}", params: patch_links_attributes.to_json

        expect(response).to be_ok, response.body
      end
    end

    context "when only a live content item exists for the link set" do
      before do
        FactoryGirl.create(:live_content_item,
          content_id: content_id,
          base_path: base_path,
        )
      end

      it "sends the live item to both content stores" do
        allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).with(anything)
        allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).with(anything)

        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_live_content_store
              .merge(payload_version: anything)
          )

        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_live_content_store
              .merge(payload_version: anything)
          )

        patch "/v2/links/#{content_id}", params: patch_links_attributes.to_json

        expect(response).to be_ok, response.body
      end
    end

    context "when draft and live content items exists for the link set" do
      before do
        draft = FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path,
          user_facing_version: 2,
        )

        FactoryGirl.create(:access_limit,
          users: access_limit_params.fetch(:users),
          content_item: draft,
        )

        FactoryGirl.create(:live_content_item,
          content_id: content_id,
          base_path: base_path,
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

        patch "/v2/links/#{content_id}", params: patch_links_attributes.to_json

        expect(response).to be_ok, response.body
      end
    end

    context "when a content item does not exist for the link set" do
      it "does not send to either content store" do
        expect(WebMock).not_to have_requested(:any, /.*content-store.*/)
        expect(PublishingAPI.service(:draft_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:live_content_store)).not_to receive(:put_content_item)

        patch "/v2/links/#{content_id}", params: patch_links_attributes.to_json

        expect(response).to be_ok, response.body
      end
    end
  end

  context "Dependency resolution" do
    include DependencyResolutionHelper

    let(:a) { create_link_set }
    let(:b) { create_link_set }

    let!(:draft_a) { create_content_item(a, "/a", "draft", "en", 2) }
    let!(:published_a) { create_content_item(a, "/a", "published") }
    let!(:draft_b) { create_content_item(b, "/b", "draft") }

    before do
      create_link(a, b, "parent")
    end

    it "sends the dependencies to the draft content store" do
      expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
        .with(a_hash_including(base_path: '/a'))
      expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
        .with(a_hash_including(base_path: '/b'))
      params = v2_content_item.merge(base_path: "/a", content_id: a,
                                     routes: [{ path: '/a', type: 'exact' }]).to_json
      put "/v2/content/#{a}", params: params
    end

    it "doesn't send draft dependencies to the live content store" do
      expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        .with(a_hash_including(base_path: '/a'))
      expect(PublishingAPI.service(:live_content_store)).to_not receive(:put_content_item)
        .with(a_hash_including(base_path: '/b'))
      post "/v2/content/#{a}/publish", params: { update_type: "major" }.to_json
    end

    it "doesn't send draft dependencies to the message queue" do
      allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
        .with(a_hash_including(base_path: '/a'))
      expect(PublishingAPI.service(:queue_publisher)).to_not receive(:send_message)
        .with(a_hash_including(base_path: '/b'))
      post "/v2/content/#{a}/publish", params: { update_type: "major" }.to_json
    end
  end

  context "/v2/publish" do
    let(:content_id) { SecureRandom.uuid }
    let!(:draft) {
      FactoryGirl.create(:draft_content_item,
        content_id: content_id,
        base_path: base_path,
      )
    }

    let(:content_item_for_live_content_store) {
      draft.attributes.deep_symbolize_keys
        .merge(
          base_path: base_path,
          locale: "en",
          document_type: "guide",
          schema_name: "guide",
          format: "guide",
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
          :last_edited_at,

          # hide attributes that won't exist when calling as_json
          :state,
          :user_facing_version
        )
    }

    it "sends to the live content store" do
      allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).with(anything)
      expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: a_hash_including(
            content_item_for_live_content_store.merge(payload_version: anything)
          )
        )

      post "/v2/content/#{content_id}/publish", params: { update_type: "major" }.to_json

      expect(response).to be_ok, response.body
    end
  end
end
