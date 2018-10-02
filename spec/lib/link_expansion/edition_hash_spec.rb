require "rails_helper"

RSpec.describe LinkExpansion::EditionHash do
  describe "from" do
    it "accepts a nil argument" do
      expect(described_class.from(nil)).to be_nil
    end
    it "accepts an array argument" do
      expect(described_class.from(["123"])).to include(
        analytics_identifier: "123"
      )
    end
    it "accepts a Hash argument" do
      expect(described_class.from(analytics_identifier: "123")).to include(
        analytics_identifier: "123"
      )
    end
    it "accepts an Edition argument" do
      edition = build(:live_edition)
      edition_hash = described_class.from(edition)
      expect(edition_hash[:content_id]).to eq(edition.content_id)
    end
    it "raises an ArgumentError otherwise" do
      expect {
        described_class.from(Time.now)
      }.to raise_error ArgumentError
    end
  end
end
