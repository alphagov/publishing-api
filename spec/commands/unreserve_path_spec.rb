RSpec.describe Commands::UnreservePath do
  describe "#call" do
    context "when the path is owned by the app" do
      it "successfully removes the reservation" do
        payload = { publishing_app: "foo", base_path: "/bar" }
        create(:path_reservation, payload)
        described_class.call(payload)
        expect(PathReservation.count).to be_zero
      end
    end

    context "when the path is not owned by the app" do
      it "returns an error" do
        payload = { base_path: "/bar", publishing_app: "foo" }

        create(
          :path_reservation,
          base_path: "/bar",
          publishing_app: "bar",
        )

        expect { described_class.call(payload) }
          .to raise_error(
            CommandError, /is reserved/
          )
      end
    end

    context "when the path has not been reserved" do
      it "returns an error" do
        payload = { base_path: "/bar" }

        expect { described_class.call(payload) }
          .to raise_error(
            CommandError, /is not reserved/
          )
      end
    end
  end
end
