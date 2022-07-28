RSpec.describe Queries::LocalesForEditions do
  def create_edition(
    content_id,
    type = :live_edition,
    user_facing_version = 1,
    locale = "en",
    base_path_prefix = "vat"
  )
    create(
      type,
      document: Document.find_or_create_by(content_id:, locale:),
      base_path: "/#{base_path_prefix}-#{locale}",
      user_facing_version:,
    )
  end

  describe ".call" do
    let(:content_id_1) { SecureRandom.uuid }
    let(:content_id_2) { SecureRandom.uuid }
    let(:base_content_ids) { [content_id_1, content_id_2] }
    let(:content_ids) { base_content_ids }
    let(:content_stores) { %w[draft live] }

    subject { described_class.call(content_ids, content_stores) }

    it { is_expected.to be_a(Array) }

    context "when there are no editions" do
      it { is_expected.to be_empty }
    end

    context "when there are two live editions in english" do
      before do
        create_edition(content_id_1, :live_edition, 1, "en", "path-1")
        create_edition(content_id_2, :live_edition, 1, "en", "path-2")
      end

      let(:results) do
        [
          [content_id_1, "en"],
          [content_id_2, "en"],
        ]
      end

      it { is_expected.to match_array(results) }
    end

    context "when there are live editions in multiple locales" do
      before do
        create_edition(content_id_1, :live_edition, 1, "en", "path-1")
        create_edition(content_id_1, :live_edition, 1, "cy", "path-1")
        create_edition(content_id_1, :live_edition, 1, "fr", "path-1")
        create_edition(content_id_2, :live_edition, 1, "es", "path-2")
        create_edition(content_id_2, :live_edition, 1, "cy", "path-2")
        create_edition(content_id_2, :live_edition, 1, "de", "path-2")
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
        create_edition(content_id_1, :live_edition, 1, "en", "path-1")
        create_edition(content_id_2, :draft_edition, 1, "en", "path-2")
      end

      let(:results) do
        [
          [content_id_1, "en"],
          [content_id_2, "en"],
        ]
      end

      it { is_expected.to match_array(results) }

      context "but we're only filtering on live " do
        let(:content_stores) { %w[live] }

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
        create_edition(content_id_1, :live_edition, 1, "en", "path-1")
        create_edition(content_id_2, :superseded_edition, 1, "en", "path-2")
      end

      let(:results) do
        [
          [content_id_1, "en"],
        ]
      end

      it { is_expected.to match_array(results) }
    end
  end
end
