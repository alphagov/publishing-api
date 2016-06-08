require "rails_helper"

RSpec.describe Adapters::ContentStore do
  describe "DEPENDENCY_FALLBACK_ORDER" do
    it "should only fallback to :published for the live content store" do
      expect(described_class::DEPENDENCY_FALLBACK_ORDER).to eq([:published])
    end

    it "cannot be modified" do
      expect {
        described_class::DEPENDENCY_FALLBACK_ORDER.unshift(:draft)
      }.to raise_error(RuntimeError, "can't modify frozen Array")
    end
  end
end
