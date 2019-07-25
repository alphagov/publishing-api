require 'rails_helper'

RSpec.describe GonePresenter do
  describe "#for_message_queue" do
    let(:payload_version) { 1 }
    let(:edition) { create(:unpublishing).edition }

    subject(:result) do
      described_class.from_edition(edition).for_message_queue(payload_version)
    end

    it "matches the notification schema" do
      expect(subject).to be_valid_against_schema("gone")
    end

    context "with a nil base_path" do
      let(:edition) { create(:gone_unpublished_edition, base_path: nil) }

      subject(:result) do
        described_class.from_edition(edition).for_message_queue(payload_version)
      end

      it "matches the notification schema" do
        expect(subject).to be_valid_against_schema("gone")
      end
    end
  end
end
