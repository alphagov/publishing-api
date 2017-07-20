require "rails_helper"

RSpec.describe LinkExpansion::ContentCache do
  def edition_attributes(edition)
    LinkExpansion::EditionHash.from(
      edition.attributes
        .merge(
          content_id: edition.content_id,
          locale: edition.locale,
          state: edition.state,
        )
    )
  end

  describe ".find" do
    let(:document) { FactoryGirl.create(:document) }
    let(:content_id) { document.content_id }
    let(:with_drafts) { false }
    let(:preload_content_ids) { [] }

    subject(:find) do
      described_class.new(
        locale: :en,
        with_drafts: with_drafts,
        preload_content_ids: preload_content_ids
      ).find(content_id)
    end

    context "no edition" do
      it { is_expected.to be_nil }
    end

    context "draft edition" do
      let!(:draft) { FactoryGirl.create(:draft_edition, document: document) }
      let!(:draft_attributes) { edition_attributes(draft) }

      context "with drafts" do
        let(:with_drafts) { true }

        it { is_expected.to eq(draft_attributes) }
      end
      context "without drafts" do
        let(:with_drafts) { false }
        it { is_expected.to be_nil }
      end
    end

    context "published edition" do
      let!(:published) { FactoryGirl.create(:live_edition, document: document) }
      let(:published_attributes) { edition_attributes(published) }

      it { is_expected.to eq(published_attributes) }
    end

    context "cached item" do
      let!(:published) { FactoryGirl.create(:live_edition, document: document) }
      before { find }

      it "doesn't run a query" do
        expect(Edition).not_to receive(:find)
        find
      end
    end

    context "preload_content_ids" do
      let!(:published) { FactoryGirl.create(:live_edition, document: document) }
      let(:preload_content_ids) { [content_id] }
      let!(:instance) do
        described_class.new(
          locale: :en,
          with_drafts: with_drafts,
          preload_content_ids: preload_content_ids
        )
      end

      it "doesn't run a query" do
        expect(Edition).not_to receive(:find)
        instance.find(content_id)
      end
    end
  end
end
