require 'rails_helper'

RSpec.describe Link do
  describe "validating link_type" do
    subject(:link) { FactoryGirl.build(:link, link_type: link_type) }
    before { link.validate }

    shared_examples "invalid link_type" do
      it { is_expected.to be_invalid }
      it "has an error on :link" do
        error = "Invalid link type: #{link_type}"
        expect(link.errors.to_hash).to eq(link: [error])
      end
    end

    context "lowercase alphanumeric link_type" do
      let(:link_type) { "word2word" }
      it { is_expected.to be_valid }
    end

    context "underscore seperated link_type" do
      let(:link_type) { "word_word" }
      it { is_expected.to be_valid }
    end

    context "uppercase characters in link_type" do
      let(:link_type) { "Uppercase" }
      include_examples "invalid link_type"
    end

    context "space characters in link_type" do
      let(:link_type) { "space space" }
      include_examples "invalid link_type"
    end

    context "dash characters in link_type" do
      let(:link_type) { "dash-ed" }
      include_examples "invalid link_type"
    end

    context "punctuation characters in link_type" do
      let(:link_type) { "punctuation!" }
      include_examples "invalid link_type"
    end

    context "available_translations link_type" do
      let(:link_type) { "available_translations" }
      include_examples "invalid link_type"
    end
  end

  describe "validating target_content_id" do
    subject(:link) { FactoryGirl.build(:link, target_content_id: target_content_id) }

    context "missing target_content_id" do
      let(:target_content_id) { SecureRandom.uuid }
      it { is_expected.to be_valid }
    end

    context "present target_content_id" do
      let(:target_content_id) { nil }
      it { is_expected.to be_invalid }
    end
  end

  describe "validating link set XOR edition association" do
    subject(:link) do
      FactoryGirl.build(:link, link_set: link_set, edition: edition)
    end
    let(:error) { "must be associated with a link set or an edition" }
    let(:link_errors) { link.errors.to_hash }
    before { link.validate }

    context "edition and link_set are nil" do
      let(:edition) { nil }
      let(:link_set) { nil }

      it { is_expected.to be_invalid }
      it "has an error on base" do
        expect(link_errors).to eq(base: [error])
      end
    end

    context "edition is not nil and link_set is nil" do
      let(:edition) { FactoryGirl.build(:edition) }
      let(:link_set) { nil }

      it { is_expected.to be_valid }
    end

    context "edition is nil and link_set is not nil" do
      let(:edition) { nil }
      let(:link_set) { FactoryGirl.build(:link_set) }

      it { is_expected.to be_valid }
    end

    context "edition and link_set are not nil" do
      let(:edition) { FactoryGirl.build(:edition) }
      let(:link_set) { FactoryGirl.build(:link_set) }

      it { is_expected.to be_invalid }
      it "has an error on base" do
        expect(link_errors).to eq(base: [error])
      end
    end
  end

  describe ".filter_editions" do
    let(:scope) { double(:scope) }

    it "modifies a scope to filter linked editions" do
      expect(scope).to receive(:joins).with(anything).and_return(scope)
      expect(scope).to receive(:where)
        .with("links.link_type": "organisations", "links.target_content_id": "12345")

      described_class.filter_editions(scope, "organisations" => "12345")
    end
  end
end
