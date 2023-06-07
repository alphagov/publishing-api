RSpec.describe Presenters::RedirectPresenter do
  describe "#for_message_queue" do
    let(:payload_version) { 1 }

    context "when the edition is an unpublished redirect" do
      let(:edition) { create(:unpublishing, type: "redirect").edition }

      subject(:result) do
        described_class.from_unpublished_edition(edition).for_message_queue(payload_version)
      end

      it "matches the notification schema" do
        expect(subject).to be_valid_against_notification_schema("redirect")
      end
    end

    context "when the edition is a published redirect" do
      let(:edition) { create(:redirect_live_edition) }

      subject(:result) do
        described_class.from_published_edition(edition).for_message_queue(payload_version)
      end

      it "matches the notification schema" do
        expect(subject).to be_valid_against_notification_schema("redirect")
      end
    end
  end
end
