RSpec.describe Presenters::SubstitutePresenter do
  describe "#for_message_queue" do
    let(:payload_version) { 1 }
    let(:edition) { create(:unpublishing, type: "substitute").edition }

    subject(:result) do
      described_class.from_edition(edition).for_message_queue(payload_version)
    end

    it "matches the notification schema" do
      expect(subject).to be_valid_against_notification_schema("substitute")
    end
  end
end
