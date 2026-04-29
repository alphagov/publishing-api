RSpec.describe PathReservation, type: :model do
  describe "validations" do
    let(:reservation) { build(:path_reservation) }

    describe "on base_path" do
      it "is a valid absolute URL base_path" do
        reservation.base_path = "not a URL"
        expect(reservation).to be_invalid
        expect(reservation.errors[:base_path].size).to eq(1)
      end

      it "has a db level uniqueness constraint" do
        create(:path_reservation, base_path: "/foo/bar")
        reservation.base_path = "/foo/bar"
        expect {
          reservation.save! validate: false
        }.to raise_error(ActiveRecord::RecordNotUnique)
      end

      it "is 512 bytes or fewer" do
        reservation.base_path = "/#{'bbc' * 171}"
        expect(reservation.base_path.bytesize).to eq(514)
        expect(reservation).to be_invalid
        expect(reservation.errors[:base_path].size).to eq(1)
      end
    end

    describe "on publishing_app" do
      it "is required" do
        reservation.publishing_app = ""
        expect(reservation).to be_invalid
        expect(reservation.errors[:publishing_app].size).to eq(1)
      end
    end
  end

  it "supports base_paths longer than 255 chars" do
    reservation = build(:path_reservation)
    reservation.base_path = "/#{'x' * 300}"
    expect {
      reservation.save!
    }.not_to raise_error
  end

  describe ".reserve_base_path!(base_path, publishing_app)" do
    context "when the path reservation already exists" do
      before do
        create(
          :path_reservation,
          base_path: "/vat-rates",
          publishing_app: "something-else",
        )
      end

      it "raises an error" do
        expect {
          described_class.reserve_base_path!("/vat-rates", "publisher")
        }.to raise_custom_record_invalid(:base_path_already_reserved, /already reserved/)
      end

      context "when override_existing is true" do
        it "updates the existing reservation" do
          expect {
            described_class.reserve_base_path!(
              "/vat-rates", "publisher", override_existing: true
            )
          }.not_to raise_error
          path_reservation = PathReservation.last

          expect(path_reservation.base_path).to eq("/vat-rates")
          expect(path_reservation.publishing_app).to eq("publisher")
        end
      end
    end

    context "when the path reservation does not exist" do
      it "creates a path reservation" do
        expect {
          described_class.reserve_base_path!("/vat-rates", "publisher")
        }.to change(PathReservation, :count).by(1)

        path_reservation = PathReservation.last

        expect(path_reservation.base_path).to eq("/vat-rates")
        expect(path_reservation.publishing_app).to eq("publisher")
      end
    end

    context "when the path reservation was created by the same app in another transaction" do
      it "returns the other reservation" do
        expect(PathReservation)
          .to receive(:create_path_reservation)
          .and_wrap_original do |m, *args|
            PathReservation.create!(publishing_app: "publisher", base_path: "/vat-rates")
            m.call(*args)
          end

        expect {
          described_class.reserve_base_path!("/vat-rates", "publisher")
        }.not_to raise_error

        path_reservation = PathReservation.last

        expect(path_reservation.base_path).to eq("/vat-rates")
        expect(path_reservation.publishing_app).to eq("publisher")
      end
    end

    context "when the path reservation was created by another app in another transaction" do
      it "returns the other reservation" do
        expect(PathReservation)
          .to receive(:create_path_reservation)
          .and_wrap_original do |m, *args|
            PathReservation.create!(publishing_app: "different", base_path: "/vat-rates")
            m.call(*args)
          end

        expect {
          described_class.reserve_base_path!("/vat-rates", "publisher")
        }.to raise_custom_record_invalid(:base_path_already_reserved, /already reserved/)
      end
    end

    it "raises an error with publishing_app_missing error code when publishing_app is blank" do
      expect {
        described_class.reserve_base_path!("/vat-rates", nil)
      }.to raise_custom_record_invalid(:publishing_app_missing, /Publishing app can't be blank/)
    end

    it "raises an error with base_path_invalid error code when base_path is not absolute" do
      expect {
        described_class.reserve_base_path!("not-a-valid-path", "publisher")
      }.to raise_custom_record_invalid(:base_path_invalid, /Base path/)
    end
  end
end
