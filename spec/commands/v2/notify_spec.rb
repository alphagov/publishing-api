require "rails_helper"

RSpec.describe Commands::V2::Notify do
  describe "call" do
    let(:base_path) { "/vat-rates" }
    let(:locale) { "en" }
    let(:user_facing_version) { 3 }
    let(:major_published_at) { 1.year.ago }
    let(:public_updated_at) { 1.year.ago }
    let(:payload_version) { 3 }

    let!(:document) do
      create(:document,
        locale: locale,
        stale_lock_version: 3)
    end

    let!(:edition) do
      create(:live_edition,
        document: document,
        base_path: base_path,
        user_facing_version: user_facing_version)
    end

    let(:payload) do
      {
        content_id: document.content_id,
        previous_version: payload_version,
        workflow_message: workflow_message,
      }
    end

    let(:workflow_message) { "Important changes to important facts about important people." }

    let(:queue_publisher) { PublishingAPI.service(:queue_publisher) }

    let(:expected_payload) do
      DownstreamPayload.new(
        edition,
        payload_version,
        draft: false,
        notification_attributes: { workflow_message: workflow_message }
      ).message_queue_payload
    end

    before do
      allow(queue_publisher).to receive(:send_message)
      allow(Event).to receive(:maximum_id).and_return(payload_version)
    end

    describe "call" do
      context "without a workflow message" do
        let(:workflow_message) { nil }

        it "raises a suitable error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, "Unprocessable entity")
        end
      end

      context "when there's a version conflict" do
        let(:payload_version) { 2 }

        it "raises a suitable error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, "Conflict")
        end
      end

      context "when no edition has been published" do
        let!(:edition) { create(:draft_edition) }

        it "raises a suitable error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, "Unprocessable entity")
        end
      end

      context "when no document exists for the payload" do
        it "raises a suitable error" do
          expect {
            described_class.call(payload.merge(content_id: SecureRandom.uuid))
          }.to raise_error(CommandError, "Not found")
        end
      end

      it "sends a message downstream" do
        described_class.call(payload)

        expect(queue_publisher).to have_received(:send_message).with(expected_payload, event_type: "workflow")
      end

      it "responses successfully" do
        expect(described_class.call(payload)).to be_a(Commands::Success)
      end
    end
  end
end
