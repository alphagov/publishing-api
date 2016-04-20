require 'rails_helper'

RSpec.describe PathReservation, type: :model do
  describe "validations" do
    let(:reservation) { build(:path_reservation) }

    describe "on base_path" do
      it "is required" do
        reservation.base_path = ''
        expect(reservation).to be_invalid
        expect(reservation.errors[:base_path].size).to eq(1)
      end

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
    end

    describe "on publishing_app" do
      it "is required" do
        reservation.publishing_app = ''
        expect(reservation).to be_invalid
        expect(reservation.errors[:publishing_app].size).to eq(1)
      end

      it "cannot be changed" do
        reservation.save!
        reservation.publishing_app = 'another_app'
        expect(reservation).to be_invalid
        expect(reservation.errors[:base_path].size).to eq(1)
      end
    end
  end

  it "supports base_paths longer than 255 chars" do
    reservation = build(:path_reservation)
    reservation.base_path = "/" + 'x' * 300
    expect {
      reservation.save!
    }.not_to raise_error
  end

  describe ".reserve_base_path!(base_path, publishing_app)" do
    context "when the path reservation already exists" do
      before do
        FactoryGirl.create(
          :path_reservation,
          base_path: "/vat-rates",
          publishing_app: "something-else",
        )
      end

      it "raises an error" do
        expect {
          described_class.reserve_base_path!("/vat-rates", "publisher")
        }.to raise_error(ActiveRecord::RecordInvalid, /already registered/)
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
        allow(PathReservation)
          .to receive(:find_or_initialize_by)
          .with(base_path: "/vat-rates")
          .and_wrap_original do |m, *args|
            record = m.call(*args)
            PathReservation.create!(publishing_app: "publisher", base_path: "/vat-rates")
            record
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
        allow(PathReservation)
          .to receive(:find_or_initialize_by)
          .with(base_path: "/vat-rates")
          .and_wrap_original do |m, *args|
            record = m.call(*args)
            PathReservation.create!(publishing_app: "something-else", base_path: "/vat-rates")
            record
          end

        expect {
          described_class.reserve_base_path!("/vat-rates", "publisher")
        }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end
end
