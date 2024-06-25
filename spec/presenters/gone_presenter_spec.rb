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

    context "with unpublished_at set" do
      let(:unpublishing) { create(:unpublishing, unpublished_at: Time.utc(2000, 1, 1)) }
      let(:edition) { unpublishing.edition }

      it "presents public_updated_at as the unpublishings unpublished_at time in UTC" do
        expect(subject[:public_updated_at]).to eql(unpublishing.unpublished_at.utc.iso8601)
      end
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
