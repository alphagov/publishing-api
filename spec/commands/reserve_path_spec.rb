require "rails_helper"

RSpec.describe Commands::ReservePath do
  describe "call" do
    let(:payload) do
      { base_path: "/foo", publishing_app: "Foo" }
    end

    context "with a new base_path" do
      it "successfully reserves the path" do
        expect(PathReservation).to receive(:reserve_base_path!)
          .with("/foo", "Foo", override_existing: false)
        expect(described_class.call(payload)).to be_a Commands::Success
      end
    end

    context "with an invalid payload" do
      it "returns a CommandError" do
        expect {
          described_class.call(base_path: "///")
        }.to raise_error CommandError
      end
    end

    context "with override_existing set" do
      let(:payload) do
        { base_path: "/foo", publishing_app: "Foo", override_existing: true }
      end
      it "passes on the flag" do
        expect(PathReservation).to receive(:reserve_base_path!)
          .with("/foo", "Foo", override_existing: true)
        expect(described_class.call(payload)).to be_a Commands::Success
      end
    end
  end
end
