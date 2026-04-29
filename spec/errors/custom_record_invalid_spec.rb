RSpec.describe CustomRecordInvalid do
  let(:record) { DummyModel.new(base_path: nil) }

  describe "#initialize" do
    it "stores the error_code" do
      error = described_class.new(record, error_code: :publishing_app_missing)

      expect(error.error_code).to eq(:publishing_app_missing)
    end

    it "inherits from ActiveRecord::RecordInvalid" do
      error = described_class.new(record, error_code: :validation_failed)

      expect(error).to be_a(ActiveRecord::RecordInvalid)
    end

    it "includes the record" do
      error = described_class.new(record, error_code: :validation_failed)

      expect(error.record).to eq(record)
    end

    it "raises an error for unknown error codes" do
      expect {
        described_class.new(record, error_code: :not_real)
      }.to raise_error(ArgumentError)
    end
  end
end

class DummyModel
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :base_path

  validates :base_path, presence: true
end
