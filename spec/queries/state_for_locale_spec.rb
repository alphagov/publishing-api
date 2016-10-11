require "rails_helper"

RSpec.describe Queries::StateForLocale do
  let(:base_content_id) { SecureRandom.uuid }
  let(:base_locale) { "en" }
  let(:base_state) { "draft" }

  let!(:base_content_item) do
    FactoryGirl.create(
      :content_item,
      content_id: base_content_id,
      locale: base_locale,
      state: base_state,
    )
  end

  describe ".conflict" do
    let(:content_item_id) { base_content_item.id + 1 }
    let(:content_id) { base_content_id }
    let(:locale) { base_locale }
    let(:state) { base_state }
    subject { described_class.conflict(content_item_id, content_id, state, locale) }

    context "when checking current item" do
      let(:content_item_id) { base_content_item.id }
      it { is_expected.to be_nil }
    end

    context "when locale is different" do
      let(:locale) { "fr" }
      it { is_expected.to be_nil }
    end

    context "when content item is different" do
      let(:content_id) { SecureRandom.uuid }
      it { is_expected.to be_nil }
    end

    {
      "draft" => { "draft" => true, "published" => false, "unpublished" => false, "superseded" => false },
      "published" => { "draft" => false, "published" => true, "unpublished" => true, "superseded" => false },
      "unpublished" => { "draft" => false, "published" => true, "unpublished" => true, "superseded" => false },
      "superseded" => { "draft" => false, "published" => false, "unpublished" => false, "superseded" => false },
    }.each do |check_state, expected_results|
      context "when state is #{check_state}" do
        let(:state) { check_state }
        expected_results.each do |base_state, should_conflict|
          context "when the existing content item is #{base_state}" do
            let(:base_state) { base_state }

            if should_conflict
              it { is_expected.to eq id: base_content_item.id }
            else
              it { is_expected.to be_nil }
            end
          end
        end
      end
    end
  end
end
