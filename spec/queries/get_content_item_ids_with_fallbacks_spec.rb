require "rails_helper"

RSpec.describe Queries::GetContentItemIdsWithFallbacks do
  describe ".call" do
    let(:state_fallback_order) { %w(published) }
    let(:locale_fallback_order) { %w(en) }
    let(:content_ids) { [] }
    let(:options) do
      {
        state_fallback_order: state_fallback_order,
        locale_fallback_order: locale_fallback_order,
      }
    end
    subject { described_class.call(content_ids, options) }

    it { is_expected.to be_a(Array) }

    context "when a content item is in a draft state" do
      let(:content_ids) { [SecureRandom.uuid] }
      let(:document) { FactoryGirl.create(:document, content_id: content_ids.first) }
      let!(:draft_content_item) do
        FactoryGirl.create(:draft_content_item, document: document)
      end

      context "and the state_fallback order is [draft]" do
        let(:state_fallback_order) { %w(draft) }
        it { is_expected.to match_array([draft_content_item.id]) }
      end

      context "and the state_fallback order is [published]" do
        let(:state_fallback_order) { %w(published) }
        it { is_expected.to be_empty }
      end

      context "and the state_fallback order is [published, draft]" do
        let(:state_fallback_order) { %w(published draft) }
        it { is_expected.to match_array([draft_content_item.id]) }
      end
    end

    context "when a content item is in draft and unpublished (withdrawn) states" do
      let(:content_ids) { [SecureRandom.uuid] }
      let(:document) { FactoryGirl.create(:document, content_id: content_ids.first) }
      let!(:draft_content_item) do
        FactoryGirl.create(:draft_content_item,
          document: document,
          user_facing_version: 2,
        )
      end
      let!(:withdrawn_content_item) do
        FactoryGirl.create(:withdrawn_unpublished_content_item,
          document: document,
          user_facing_version: 1,
        )
      end

      context "and the state_fallback order is [draft, withdrawn]" do
        let(:state_fallback_order) { %w(draft withdrawn) }
        it { is_expected.to match_array([draft_content_item.id]) }
      end

      context "and the state_fallback order is [withdrawn, draft]" do
        let(:state_fallback_order) { %w(withdrawn draft) }
        it { is_expected.to match_array([withdrawn_content_item.id]) }
      end
    end

    context "when a content item is in multiple locales" do
      let(:content_ids) { [SecureRandom.uuid] }
      let(:fr_document) do
        FactoryGirl.create(:document,
          content_id: content_ids.first,
          locale: "fr",
        )
      end
      let(:en_document) do
        FactoryGirl.create(:document,
          content_id: content_ids.first,
          locale: "en",
        )
      end
      let!(:fr_draft_content_item) do
        FactoryGirl.create(:draft_content_item, document: fr_document)
      end
      let!(:en_draft_content_item) do
        FactoryGirl.create(:draft_content_item,
          document: en_document,
          user_facing_version: 2,
        )
      end
      let!(:en_published_content_item) do
        FactoryGirl.create(:live_content_item,
          document: en_document,
          user_facing_version: 1,
        )
      end

      context "and the locale_fallback_order is [fr]" do
        let(:locale_fallback_order) { %w(fr) }

        context "and the state_fallback_order is [draft]" do
          let(:state_fallback_order) { %w(draft) }
          it { is_expected.to match_array(fr_draft_content_item.id) }
        end

        context "and the state_fallback_order is [published]" do
          let(:state_fallback_order) { %w(published) }
          it { is_expected.to be_empty }
        end
      end

      context "and the locale_fallback_order is [fr, en]" do
        let(:locale_fallback_order) { %w(fr en) }

        context "and the state_fallback_order is [draft]" do
          let(:state_fallback_order) { %w(draft) }
          it { is_expected.to match_array(fr_draft_content_item.id) }
        end

        context "and the state_fallback_order is [published]" do
          let(:state_fallback_order) { %w(published) }
          it { is_expected.to match_array(en_published_content_item.id) }
        end
      end

      context "and the locale_fallback_order is [en, fr]" do
        let(:locale_fallback_order) { %w(en fr) }

        context "and the state_fallback_order is [draft]" do
          let(:state_fallback_order) { %w(draft) }
          it { is_expected.to match_array(en_draft_content_item.id) }
        end

        context "and the state_fallback_order is [published]" do
          let(:state_fallback_order) { %w(published) }
          it { is_expected.to match_array(en_published_content_item.id) }
        end
      end
    end

    context "when multiple content items are requested" do
      let(:content_ids) { [SecureRandom.uuid, SecureRandom.uuid] }
      let(:vat_document) { FactoryGirl.create(:document, content_id: content_ids.first) }
      let(:tax_rates_document) { FactoryGirl.create(:document, content_id: content_ids.last) }
      let!(:vat_draft_content_item) do
        FactoryGirl.create(:draft_content_item,
          document: vat_document,
          user_facing_version: 2,
        )
      end
      let!(:vat_published_content_item) do
        FactoryGirl.create(:live_content_item,
          document: vat_document,
          user_facing_version: 1,
        )
      end
      let!(:tax_rates_draft_content_item) do
        FactoryGirl.create(:draft_content_item,
          document: tax_rates_document,
          user_facing_version: 2,
        )
      end
      let!(:tax_rates_withdrawn_content_item) do
        FactoryGirl.create(:withdrawn_unpublished_content_item,
          document: tax_rates_document,
          user_facing_version: 1,
        )
      end

      context "and the state_fallback order is [draft, published]" do
        let(:state_fallback_order) { %w(draft published) }
        let(:expected) { [vat_draft_content_item.id, tax_rates_draft_content_item.id] }
        it { is_expected.to match_array(expected) }
      end

      context "and the state_fallback order is [published, draft]" do
        let(:state_fallback_order) { %w(published draft) }
        let(:expected) { [vat_published_content_item.id, tax_rates_draft_content_item.id] }
        it { is_expected.to match_array(expected) }
      end

      context "and the state_fallback order is [withdrawn, draft]" do
        let(:state_fallback_order) { %w(withdrawn draft) }
        let(:expected) { [vat_draft_content_item.id, tax_rates_withdrawn_content_item.id] }
        it { is_expected.to match_array(expected) }
      end
    end

    context "when there is a non-renderable document type" do
      let(:content_ids) { [SecureRandom.uuid] }
      let(:document) { FactoryGirl.create(:document, content_id: content_ids.first) }
      let!(:draft_content_item) do
        FactoryGirl.create(:draft_content_item,
          document: document,
          document_type: "gone",
          user_facing_version: 2,
        )
      end
      let!(:published_content_item) do
        FactoryGirl.create(:live_content_item,
          document: document,
          user_facing_version: 1,
        )
      end

      context "and the state_fallback order is [draft]" do
        let(:state_fallback_order) { %w(draft) }
        it { is_expected.to be_empty }
      end

      context "and the state_fallback order is [published]" do
        let(:state_fallback_order) { %w(published) }
        it { is_expected.to match_array([published_content_item.id]) }
      end

      context "and the state_fallback order is [draft, published]" do
        let(:state_fallback_order) { %w(draft published) }
        it { is_expected.to match_array([published_content_item.id]) }
      end
    end
  end
end
