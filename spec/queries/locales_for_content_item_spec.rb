require "rails_helper"

RSpec.describe Queries::LocalesForContentItem do
  describe '.call' do
    let(:base_content_id) { "05626609-f046-41cc-ba84-a07d1064ac96" }
    let(:content_id) { base_content_id }
    let(:states) { %w[draft published unpublished] }
    let(:include_substitutes) { false }

    subject { described_class.call(content_id, states, include_substitutes) }

    before do
      FactoryGirl.create(
        :live_content_item,
        content_id: base_content_id,
        locale: "en",
        base_path: "/vat-en",
        user_facing_version: 1,
      )

      FactoryGirl.create(
        :draft_content_item,
        content_id: base_content_id,
        locale: "en",
        base_path: "/vat-en",
        user_facing_version: 2,
      )

      FactoryGirl.create(
        :draft_content_item,
        content_id: base_content_id,
        locale: "fr",
        base_path: "/vat-fr",
        user_facing_version: 1,
      )

      FactoryGirl.create(
        :unpublished_content_item,
        content_id: base_content_id,
        locale: "es",
        base_path: "/vat-es",
        user_facing_version: 1,
      )

      FactoryGirl.create(
        :superseded_content_item,
        content_id: base_content_id,
        locale: "de",
        base_path: "/vat-de",
        user_facing_version: 1,
      )

      FactoryGirl.create(
        :substitute_unpublished_content_item,
        content_id: base_content_id,
        locale: "cy",
        base_path: "/vat-cy",
        user_facing_version: 1,
      )
    end

    it { is_expected.to be_a(Array) }

    context "where there are no content items for the content id" do
      let(:content_id) { "43466ca6-46d4-4a92-9783-c29a40cc77e3" }
      it { is_expected.to be_empty }
    end

    context "when we access draft, published and unpublished content items, excluding substitute unpublishings" do
      let(:states) { %w[draft published unpublished] }
      let(:include_substitutes) { false }
      it { is_expected.to match_array(%w[en fr es]) }

      context "when states are symbols" do
        let(:states) { %i[draft published unpublished] }
        it { is_expected.to match_array(%w[en fr es]) }
      end
    end

    context "when we access draft items" do
      let(:states) { %w[draft] }

      it { is_expected.to match_array(%w[en fr]) }
    end

    context "when we access published items" do
      let(:states) { %w[published] }

      it { is_expected.to match_array(%w[en]) }
    end

    context "when we access unpublished items, without substitutes" do
      let(:states) { %w[unpublished] }

      it { is_expected.to match_array(%w[es]) }
    end

    context "when we access unpublished items, with substitutes" do
      let(:states) { %w[unpublished] }
      let(:include_substitutes) { true }

      it { is_expected.to match_array(%w[es cy]) }
    end

    context "when we access superseded items" do
      let(:states) { %w[superseded] }

      it { is_expected.to match_array(%w[de]) }
    end
  end
end
