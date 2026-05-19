RSpec.describe Unpublishing do
  describe "validations" do
    subject { build(:unpublishing) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "requires a valid type" do
      valid_types = %w[
        gone
        vanish
        substitute
        withdrawal
      ]

      valid_types.each do |type|
        subject.type = type
        expect(subject).to be_valid
      end

      subject.type = "anything-else"
      expect(subject).to be_invalid
      expect(subject.errors[:type].size).to eq(1)

      # because we haven't given any 'redirects'
      subject.type = "redirect"
      expect(subject).to be_invalid
      expect(subject.errors[:redirects].size).to eq(2)
      expect(subject.errors.added?(:redirects, "must include the base path", code: :redirects_must_include_base_path)).to be true

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

    it "requires a redirects blob for a 'redirect'" do
      subject.type = "redirect"
      subject.alternative_path = nil
      subject.redirects = nil
      expect(subject).to be_invalid
      expect(subject.errors[:redirects].size).to eq(2)
    end

    context "when alternative_path is equal to base_path" do
      let(:base_path) { "/new-path" }
      let(:edition) do
        create(
          :edition,
          base_path:,
        )
      end

      it "is invalid" do
        subject.edition = edition
        subject.type = "redirect"
        subject.redirects = [{ path: base_path, type: :exact, destination: base_path }]

        expect(subject).to be_invalid
        expect(subject.errors[:redirects]).to include(
          "path cannot equal the destination",
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

  describe ".is_substitute?" do
    subject { described_class.is_substitute?(edition) }
    context "when unpublished with type 'substitute'" do
      let(:edition) { create(:substitute_unpublished_edition) }
      it { is_expected.to be true }
    end
    context "when unpublished with type 'gone'" do
      let(:edition) { create(:gone_unpublished_edition) }
      it { is_expected.to be false }
    end
    context "when edition is published" do
      let(:edition) { create(:live_edition) }
      it { is_expected.to be false }
    end
    context "when there isn't an edition" do
      let(:edition) { nil }
      it { is_expected.to be false }
    end
  end

  describe "#save!" do
    let(:edition) { create(:edition, base_path: "/test") }

    it "adds edition_missing error code when edition is missing" do
      record = described_class.new(type: "gone")

      expect_error_code(
        record: record,
        attribute: :edition,
        error: :blank,
        code: :edition_missing,
      )
    end

    it "returns edition_not_unique error code when edition is not unique" do
      create(:unpublishing, edition: edition)

      duplicate = build(:unpublishing, edition: edition)

      expect_error_code(
        record: duplicate,
        attribute: :edition,
        error: :taken,
        code: :edition_not_unique,
      )
    end

    it "adds type_missing error code when type is invalid" do
      record = described_class.new(edition: edition)

      expect_error_code(
        record: record,
        attribute: :type,
        error: :blank,
        code: :type_missing,
      )
    end

    it "adds type_invalid error code when type is invalid" do
      record = described_class.new(
        edition: edition,
        type: "not_a_valid_type",
      )

      expect_error_code(
        record: record,
        attribute: :type,
        error: :inclusion,
        code: :type_invalid,
      )
    end

    it "adds explanation_missing_for_withdrawal error code when explanation is missing" do
      record = described_class.new(
        edition: edition,
        type: "withdrawal",
        explanation: nil,
      )

      expect_error_code(
        record: record,
        attribute: :explanation,
        error: :blank,
        code: :explanation_missing_for_withdrawal,
      )
    end

    it "adds redirects_missing_for_redirect error code when redirects are missing" do
      record = described_class.new(
        edition: edition,
        type: "redirect",
        redirects: nil,
      )

      expect_error_code(
        record: record,
        attribute: :redirects,
        error: :blank,
        code: :redirects_missing_for_redirect,
      )
    end

    def expect_error_code(record:, attribute:, error:, code:)
      expect { record.save! }
        .to raise_error(ActiveRecord::RecordInvalid) { |exception|
          expect(exception.record.errors.details[attribute]).to include(
            a_hash_including(error: error, code: code),
          )
        }
    end
  end
end
