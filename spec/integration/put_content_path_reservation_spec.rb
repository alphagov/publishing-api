require "rails_helper"

RSpec.describe Commands::V2::PutContent do
  include IntegrationSpecHelper

  describe "call" do
    let(:payload) { default_payload }

    context "when there are no previous path reservations" do
      it "creates a path reservation" do
        expect {
          described_class.call(payload)
        }.to change(PathReservation, :count).by(1)

        reservation = PathReservation.last
        expect(reservation.base_path).to eq("/vat-rates")
        expect(reservation.publishing_app).to eq("publisher")
      end
    end

    context "when the base path has been reserved by another publishing app" do
      before do
        FactoryGirl.create(:path_reservation,
          base_path: base_path,
          publishing_app: "something-else"
        )
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /is already reserved/i)
      end
    end
  end
end
