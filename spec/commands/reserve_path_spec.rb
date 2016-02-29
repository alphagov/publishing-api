require "rails_helper"

RSpec.describe Commands::ReservePath do
  describe "call" do
    let(:payload) {
      { base_path: "/foo", publishing_app: "Foo" }
    }

    context "with a new base_path" do
      it "successfully reserves the path" do
        expect(PathReservation).to receive(:reserve_base_path!).with("/foo", "Foo")
        expect(described_class.call(payload)).to be_a Commands::Success
      end
    end

    context "with an invalid payload" do
      it "returns a CommandError" do
        expect {
          described_class.call({ base_path: "///" })
        }.to raise_error CommandError
      end
    end

    context "when the downstream flag is set to false" do
      it "does not send any downstream requests" do
        expect(ContentStoreWorker).not_to receive(:perform_in)
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

        described_class.call(payload, downstream: false)
      end
    end
  end
end
