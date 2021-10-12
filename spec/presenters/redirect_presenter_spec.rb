require "rails_helper"

RSpec.describe RedirectPresenter do
  let(:payload_version) { 1 }

  describe "#for_message_queue" do
    let(:edition) { create(:unpublishing, type: "redirect").edition }

    subject(:result) do
      described_class.from_edition(edition).for_message_queue(payload_version)
    end

    it "matches the notification schema" do
      expect(subject).to be_valid_against_notification_schema("redirect")
    end
  end

  describe "#for_content_store" do
    it "skips over the original redirect and redirects directly to the latest path" do
      create(:unpublished_edition, base_path: "/original-base-path", alternative_path: "/redirected-path")
      second_edition = create(:unpublished_edition, base_path: "/foo", alternative_path: "/original-base-path")
      subject = described_class.from_edition(second_edition).for_content_store(payload_version)

      expect(subject[:redirects].first[:destination]).to eq("/redirected-path")
    end
  end
end
