require 'rails_helper'

RSpec.describe PathReservation, :type => :model do
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
        create(:path_reservation, :base_path => "/foo/bar")
        reservation.base_path = "/foo/bar"
        expect {
          reservation.save! :validate => false
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

  let(:payload) {
    FactoryGirl.build(:path_reservation)
    .as_json
    .symbolize_keys
  }

  let(:another_payload) {
    FactoryGirl.build(:path_reservation)
    .as_json
    .symbolize_keys
    .merge(publishing_app: "not-publisher")
  }

  let!(:existing) { create(:path_reservation, payload) }

  def set_new_attributes(item)
    # empty because there are no changeable attributes
  end

  def verify_new_attributes_set
    # empty because there are no changeable attributes
  end

  it_behaves_like Replaceable
end
