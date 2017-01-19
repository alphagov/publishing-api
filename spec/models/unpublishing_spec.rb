require "rails_helper"

RSpec.describe Unpublishing do
  describe "validations" do
    subject { FactoryGirl.build(:unpublishing) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "requires a valid type" do
      valid_types = %w(
        gone
        vanish
        redirect
        substitute
        withdrawal
      )

      valid_types.each do |type|
        subject.type = type
        expect(subject).to be_valid
      end

      subject.type = "anything-else"
      expect(subject).to be_invalid
      expect(subject.errors[:type].size).to eq(1)

      subject.type = nil
      expect(subject).to be_invalid
      expect(subject.errors[:type].size).to eq(2)
    end

    it "does not require an explanation for a 'gone'" do
      subject.type = "gone"
      subject.explanation = nil
      expect(subject).to be_valid
    end

    it "requires an explanation for a 'withdrawal'" do
      subject.type = "withdrawal"
      subject.explanation = nil
      expect(subject).to be_invalid
      expect(subject.errors[:explanation].size).to eq(1)
    end

    it "does not require an alternative_path for a 'gone'" do
      subject.type = "gone"
      subject.alternative_path = nil
      expect(subject).to be_valid
    end

    it "requires an alternative_path for a 'redirect'" do
      subject.type = "redirect"
      subject.alternative_path = nil
      expect(subject).to be_invalid
      expect(subject.errors[:alternative_path].size).to eq(1)
    end

    context "when alternative_path is equal to base_path" do
      let(:base_path) { "/new-path" }
      let(:edition) do
        FactoryGirl.create(:edition,
          base_path: base_path,
        )
      end

      it "is invalid" do
        subject.edition = edition
        subject.type = "redirect"
        subject.alternative_path = base_path

        expect(subject).to be_invalid
        expect(subject.errors[:alternative_path]).to include(
          "base_path matches the unpublishing alternative_path #{base_path}"
        )
      end
    end

    it "does not require anything for 'vanish'" do
      subject.type = "vanish"
      subject.alternative_path = nil
      subject.explanation = nil
      expect(subject).to be_valid
    end
  end

  describe ".is_subtitute?" do
    subject { described_class.is_substitute?(edition) }
    context "when unpublished with type 'substitute'" do
      let(:edition) { FactoryGirl.create(:substitute_unpublished_content_item) }
      it { is_expected.to be true }
    end
    context "when unpublished with type 'gone'" do
      let(:edition) { FactoryGirl.create(:gone_unpublished_content_item) }
      it { is_expected.to be false }
    end
    context "when content item is published" do
      let(:edition) { FactoryGirl.create(:live_content_item) }
      it { is_expected.to be false }
    end
    context "when there isn't a content item" do
      let(:edition) { nil }
      it { is_expected.to be false }
    end
  end
end
