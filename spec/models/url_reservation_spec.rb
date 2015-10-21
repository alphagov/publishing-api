require 'rails_helper'

RSpec.describe UrlReservation, :type => :model do
  describe "validations" do
    let(:reservation) { build(:url_reservation) }

    describe "on base_path" do

      it "is required" do
        reservation.base_path = ''
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base_path].size).to eq(1)
      end

      it "is a valid absolute URL base_path" do
        reservation.base_path = "not a URL"
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base_path].size).to eq(1)
      end

      it "is unique" do
        create(:url_reservation, :base_path => "/foo/bar")
        reservation.base_path = "/foo/bar"
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base_path].size).to eq(1)
      end

      it "has a db level uniqueness constraint" do
        create(:url_reservation, :base_path => "/foo/bar")
        reservation.base_path = "/foo/bar"
        expect {
          reservation.save! :validate => false
        }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    describe "on publishing_app" do
      it "is required" do
        reservation.publishing_app = ''
        expect(reservation).not_to be_valid
        expect(reservation.errors[:publishing_app].size).to eq(1)
      end

      it "cannot be changed" do
        reservation.save!
        reservation.publishing_app = 'another_app'
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base_path].size).to eq(1)
      end
    end
  end

  it "supports base_paths longer than 255 chars" do
    reservation = build(:url_reservation)
    reservation.base_path = "/" + 'x' * 300
    expect {
      reservation.save!
    }.not_to raise_error
  end
end
