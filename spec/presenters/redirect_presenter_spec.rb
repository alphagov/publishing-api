require "rails_helper"

RSpec.describe RedirectPresenter do
  describe "#for_message_queue" do
    let(:payload_version) { 1 }
    let(:edition) { create(:unpublishing, type: "redirect").edition }

    subject(:result) do
      described_class.from_edition(edition).for_message_queue(payload_version)
    end

    it "matches the notification schema" do
      expect(subject).to be_valid_against_schema("redirect")
    end
  end
end
