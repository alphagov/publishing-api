require "rails_helper"

RSpec.describe Queries::GetExpandedLinks do
  let(:content_id) { SecureRandom.uuid }

  context "when the document does not exist" do
    it "raises a command error" do
      expect {
        described_class.call(content_id, "en")
      }.to raise_error(CommandError, /could not find link set/i)
    end
  end

  context "when a document exists without a link set" do
    before do
      FactoryGirl.create(:document, content_id: content_id)
    end

    it "returns an empty response" do
      result = described_class.call(content_id, "en")

      expect(result).to eq(
        content_id: content_id,
        version: 0,
        expanded_links: {},
      )
    end
  end
end
