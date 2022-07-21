RSpec.describe Queries::GetEditionIdsWithFallbacks do
  describe ".call" do
    let(:state_fallback_order) { %w[published] }
    let(:locale_fallback_order) { %w[en] }
    let(:content_ids) { [] }
    let(:options) do
      {
        state_fallback_order: state_fallback_order,
        locale_fallback_order: locale_fallback_order,
      }
    end
    subject { described_class.call(content_ids, **options) }

    it { is_expected.to be_a(Array) }

    context "when a edition is in a draft state" do
      let(:content_ids) { [SecureRandom.uuid] }
      let(:document) { create(:document, content_id: content_ids.first) }
      let!(:draft_edition) do
        create(:draft_edition, document: document)
      end

      context "and the state_fallback order is [draft]" do
        let(:state_fallback_order) { %w[draft] }
        it { is_expected.to match_array([draft_edition.id]) }
      end

      context "and the state_fallback order is [published]" do
        let(:state_fallback_order) { %w[published] }
        it { is_expected.to be_empty }
      end

      context "and the state_fallback order is [published, draft]" do
        let(:state_fallback_order) { %w[published draft] }
        it { is_expected.to match_array([draft_edition.id]) }
      end
    end

    context "when a edition is in draft and unpublished (withdrawn) states" do
      let(:content_ids) { [SecureRandom.uuid] }
      let(:document) { create(:document, content_id: content_ids.first) }
      let!(:draft_edition) do
        create(
          :draft_edition,
          document: document,
          user_facing_version: 2,
        )
      end
      let!(:withdrawn_edition) do
        create(
          :withdrawn_unpublished_edition,
          document: document,
          user_facing_version: 1,
        )
      end

      context "and the state_fallback order is [draft, withdrawn]" do
        let(:state_fallback_order) { %w[draft withdrawn] }
        it { is_expected.to match_array([draft_edition.id]) }
      end

      context "and the state_fallback order is [withdrawn, draft]" do
        let(:state_fallback_order) { %w[withdrawn draft] }
        it { is_expected.to match_array([withdrawn_edition.id]) }
      end
    end

    context "when a edition is in multiple locales" do
      let(:content_ids) { [SecureRandom.uuid] }
      let(:fr_document) do
        create(
          :document,
          content_id: content_ids.first,
          locale: "fr",
        )
      end
      let(:en_document) do
        create(
          :document,
          content_id: content_ids.first,
          locale: "en",
        )
      end
      let!(:fr_draft_edition) do
        create(:draft_edition, document: fr_document)
      end
      let!(:en_draft_edition) do
        create(
          :draft_edition,
          document: en_document,
          user_facing_version: 2,
        )
      end
      let!(:en_published_edition) do
        create(
          :live_edition,
          document: en_document,
          user_facing_version: 1,
        )
      end

      context "and the locale_fallback_order is [fr]" do
        let(:locale_fallback_order) { %w[fr] }

        context "and the state_fallback_order is [draft]" do
          let(:state_fallback_order) { %w[draft] }
          it { is_expected.to match_array(fr_draft_edition.id) }
        end

        context "and the state_fallback_order is [published]" do
          let(:state_fallback_order) { %w[published] }
          it { is_expected.to be_empty }
        end
      end

      context "and the locale_fallback_order is [fr, en]" do
        let(:locale_fallback_order) { %w[fr en] }

        context "and the state_fallback_order is [draft]" do
          let(:state_fallback_order) { %w[draft] }
          it { is_expected.to match_array(fr_draft_edition.id) }
        end

        context "and the state_fallback_order is [published]" do
          let(:state_fallback_order) { %w[published] }
          it { is_expected.to match_array(en_published_edition.id) }
        end
      end

      context "and the locale_fallback_order is [en, fr]" do
        let(:locale_fallback_order) { %w[en fr] }

        context "and the state_fallback_order is [draft]" do
          let(:state_fallback_order) { %w[draft] }
          it { is_expected.to match_array(en_draft_edition.id) }
        end

        context "and the state_fallback_order is [published]" do
          let(:state_fallback_order) { %w[published] }
          it { is_expected.to match_array(en_published_edition.id) }
        end
      end
    end

    context "when multiple editions are requested" do
      let(:content_ids) { [SecureRandom.uuid, SecureRandom.uuid] }
      let(:vat_document) { create(:document, content_id: content_ids.first) }
      let(:tax_rates_document) { create(:document, content_id: content_ids.last) }
      let!(:vat_draft_edition) do
        create(
          :draft_edition,
          document: vat_document,
          user_facing_version: 2,
        )
      end
      let!(:vat_published_edition) do
        create(
          :live_edition,
          document: vat_document,
          user_facing_version: 1,
        )
      end
      let!(:tax_rates_draft_edition) do
        create(
          :draft_edition,
          document: tax_rates_document,
          user_facing_version: 2,
        )
      end
      let!(:tax_rates_withdrawn_edition) do
        create(
          :withdrawn_unpublished_edition,
          document: tax_rates_document,
          user_facing_version: 1,
        )
      end

      context "and the state_fallback order is [draft, published]" do
        let(:state_fallback_order) { %w[draft published] }
        let(:expected) { [vat_draft_edition.id, tax_rates_draft_edition.id] }
        it { is_expected.to match_array(expected) }
      end

      context "and the state_fallback order is [published, draft]" do
        let(:state_fallback_order) { %w[published draft] }
        let(:expected) { [vat_published_edition.id, tax_rates_draft_edition.id] }
        it { is_expected.to match_array(expected) }
      end

      context "and the state_fallback order is [withdrawn, draft]" do
        let(:state_fallback_order) { %w[withdrawn draft] }
        let(:expected) { [vat_draft_edition.id, tax_rates_withdrawn_edition.id] }
        it { is_expected.to match_array(expected) }
      end
    end

    context "when there is a non-renderable document type" do
      let(:content_ids) { [SecureRandom.uuid] }
      let(:document) { create(:document, content_id: content_ids.first) }
      let!(:draft_edition) do
        create(
          :draft_edition,
          document: document,
          document_type: "gone",
          user_facing_version: 2,
        )
      end
      let!(:published_edition) do
        create(
          :live_edition,
          document: document,
          user_facing_version: 1,
        )
      end

      context "and the state_fallback order is [draft]" do
        let(:state_fallback_order) { %w[draft] }
        it { is_expected.to be_empty }
      end

      context "and the state_fallback order is [published]" do
        let(:state_fallback_order) { %w[published] }
        it { is_expected.to match_array([published_edition.id]) }
      end

      context "and the state_fallback order is [draft, published]" do
        let(:state_fallback_order) { %w[draft published] }
        it { is_expected.to match_array([published_edition.id]) }
      end
    end
  end
end
