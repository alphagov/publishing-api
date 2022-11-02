RSpec.describe Presenters::GonePresenter do
  describe "#for_message_queue" do
    let(:payload_version) { 1 }
    let(:edition) { create(:unpublishing).edition }

    subject(:result) do
      described_class.from_edition(edition).for_message_queue(payload_version)
    end

    it "matches the notification schema" do
      expect(subject).to be_valid_against_notification_schema("gone")
    end

    context "with a nil base_path" do
      let(:edition) { create(:gone_unpublished_edition, base_path: nil) }

      subject(:result) do
        described_class.from_edition(edition).for_message_queue(payload_version)
      end

      it "matches the notification schema" do
        expect(subject).to be_valid_against_notification_schema("gone")
      end
    end

    context "with more than one route" do
      let(:base_path) { "/government/document" }

      let(:routes) do
        [
          {
            path: base_path,
            type: "exact",
          },
          {
            path: "#{base_path}.atom",
            type: "exact",
          },
        ]
      end

      let(:edition) { create(:gone_unpublished_edition, base_path:, routes:) }

      subject(:result) do
        described_class.from_edition(edition).for_message_queue(payload_version)
      end

      it "presents all the routes" do
        expect(subject[:routes]).to eq(routes)
      end
    end
  end
end
