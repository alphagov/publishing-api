require "rails_helper"

RSpec.describe Queries::LocalesForContentItem do
  def create_content_item(
    content_id,
    type = :live_content_item,
    user_facing_version = 1,
    locale = "en",
    base_path_prefix = "vat"
  )
    FactoryGirl.create(
      type,
      content_id: content_id,
      locale: locale,
      base_path: "/#{base_path_prefix}-#{locale}",
      user_facing_version: user_facing_version,
    )
  end

  describe '.for_one' do
    let(:base_content_id) { "05626609-f046-41cc-ba84-a07d1064ac96" }
    let(:content_id) { base_content_id }
    let(:states) { %w[draft published unpublished] }
    let(:include_substitutes) { false }

    subject { described_class.for_one(content_id, states, include_substitutes) }

    before do
      create_content_item(base_content_id)
      create_content_item(base_content_id, :draft_content_item, 2)
      create_content_item(base_content_id, :draft_content_item, 1, "fr")
      create_content_item(base_content_id, :unpublished_content_item, 1, "es")
      create_content_item(base_content_id, :superseded_content_item, 1, "de")
      create_content_item(base_content_id, :substitute_unpublished_content_item, 1, "cy")
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

  describe ".for_many" do
    let(:content_id_1) { SecureRandom.uuid }
    let(:content_id_2) { SecureRandom.uuid }
    let(:base_content_ids) { [content_id_1, content_id_2] }
    let(:content_ids) { base_content_ids }
    let(:states) { %w[draft published unpublished] }
    let(:include_substitutes) { false }

    subject { described_class.for_many(content_ids, states, include_substitutes) }

    it { is_expected.to be_a(Array) }

    context "when there are no content items" do
      it { is_expected.to be_empty }
    end

    context "when there are two live content items in english" do
      before do
        create_content_item(content_id_1, :live_content_item, 1, "en", "path-1")
        create_content_item(content_id_2, :live_content_item, 1, "en", "path-2")
      end

      let(:results) do
        [
          [content_id_1, "en"],
          [content_id_2, "en"],
        ]
      end

      it { is_expected.to match_array(results) }
    end

    context "when there are live content items in multiple locales" do
      before do
        create_content_item(content_id_1, :live_content_item, 1, "en", "path-1")
        create_content_item(content_id_1, :live_content_item, 1, "cy", "path-1")
        create_content_item(content_id_1, :live_content_item, 1, "fr", "path-1")
        create_content_item(content_id_2, :live_content_item, 1, "es", "path-2")
        create_content_item(content_id_2, :live_content_item, 1, "cy", "path-2")
        create_content_item(content_id_2, :live_content_item, 1, "de", "path-2")
      end

      let(:results) do
        [
          [content_id_1, "cy"],
          [content_id_1, "en"],
          [content_id_1, "fr"],
          [content_id_2, "cy"],
          [content_id_2, "de"],
          [content_id_2, "es"],
        ]
      end

      it { is_expected.to match_array(results) }
    end

    context "when some of the items are drafts" do
      before do
        create_content_item(content_id_1, :live_content_item, 1, "en", "path-1")
        create_content_item(content_id_2, :draft_content_item, 1, "en", "path-2")
      end

      let(:results) do
        [
          [content_id_1, "en"],
          [content_id_2, "en"],
        ]
      end

      it { is_expected.to match_array(results) }

      context "but we're only filtering on published / unpublished" do
        let(:states) { %w[published unpublished] }

        let(:results) do
          [
            [content_id_1, "en"],
          ]
        end

        it { is_expected.to match_array(results) }
      end
    end

    context "when some of the items are superseded" do
      before do
        create_content_item(content_id_1, :live_content_item, 1, "en", "path-1")
        create_content_item(content_id_2, :superseded_content_item, 1, "en", "path-2")
      end

      let(:results) do
        [
          [content_id_1, "en"],
        ]
      end

      it { is_expected.to match_array(results) }
    end

    context "when some of the items are unpublished type substite" do
      before do
        create_content_item(content_id_1, :live_content_item, 1, "en", "path-1")
        create_content_item(content_id_2, :substitute_unpublished_content_item, 1, "en", "path-2")
      end

      let(:results) do
        [
          [content_id_1, "en"],
        ]
      end

      it { is_expected.to match_array(results) }

      context "and we're including substitutes" do
        let(:include_substitutes) { true }

        let(:results) do
          [
            [content_id_1, "en"],
            [content_id_2, "en"],
          ]
        end

        it { is_expected.to match_array(results) }
      end
    end
  end
end
