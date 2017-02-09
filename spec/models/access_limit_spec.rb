require "rails_helper"

RSpec.describe AccessLimit do
  subject do
    FactoryGirl.build(:access_limit,
      users: users,
      fact_check_ids: fact_check_ids,
    )
  end

  let(:users) { [SecureRandom.uuid] }
  let(:fact_check_ids) { [] }

  it { is_expected.to be_valid }

  describe "validates users" do
    context "where users has an array with a string" do
      let(:users) { [SecureRandom.uuid] }
      it { is_expected.to be_valid }
    end

    context "where users has an array with an integer" do
      let(:users) { [123] }
      it { is_expected.to be_invalid }
    end
  end

  describe "validates fact_check_ids" do
    context "where fact_check_ids has an array with a uuids" do
      let(:fact_check_ids) { [SecureRandom.uuid, SecureRandom.uuid] }
      it { is_expected.to be_valid }
    end

    context "where fact_check_ids has an array with non uuids" do
      let(:fact_check_ids) { ["not-a-uuid"] }
      it { is_expected.to be_invalid }
    end

    context "where users has an array with an integer" do
      let(:fact_check_ids) { [123] }
      it { is_expected.to be_invalid }
    end
  end
end
