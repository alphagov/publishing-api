require "rails_helper"

RSpec.describe LinkExpansion::ContentCache do
  describe ".find" do
    let(:document) { FactoryGirl.create(:document) }
    let(:content_id) { document.content_id }
    let(:with_drafts) { false }
    let(:preload_content_ids) { [] }

    subject(:find) do
      described_class.new(
        with_drafts: with_drafts,
        locale_fallback_order: [:en],
        preload_content_ids: preload_content_ids
      ).find(content_id)
    end

    context "no content item" do
      it { is_expected.to be_nil }
    end

    context "draft content item" do
      let!(:draft) { FactoryGirl.create(:draft_edition, document: document) }

      context "with drafts" do
        let(:with_drafts) { true }

        let(:web_content_item) { Queries::GetWebContentItems.find(draft.id) }
        it { is_expected.to eq(web_content_item) }
      end
      context "without drafts" do
        let(:with_drafts) { false }
        it { is_expected.to be_nil }
      end
    end

    context "published content item" do
      let!(:published) { FactoryGirl.create(:live_edition, document: document) }

      let(:web_content_item) { Queries::GetWebContentItems.find(published.id) }
      it { is_expected.to eq(web_content_item) }
    end

    context "cached item" do
      let!(:published) { FactoryGirl.create(:live_edition, document: document) }
      before { find }

      it "doesn't run a query" do
        expect(Queries::GetWebContentItems).not_to receive(:call)
        find
      end
    end

    context "preload_content_ids" do
      let!(:published) { FactoryGirl.create(:live_edition, document: document) }
      let(:preload_content_ids) { [content_id] }
      let!(:instance) do
        described_class.new(
          with_drafts: with_drafts,
          locale_fallback_order: [:en],
          preload_content_ids: preload_content_ids
        )
      end

      it "doesn't run a query" do
        expect(Queries::GetWebContentItems).not_to receive(:call)
        instance.find(content_id)
      end
    end
  end
end
