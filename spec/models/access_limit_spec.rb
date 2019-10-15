require "rails_helper"

RSpec.describe AccessLimit do
  subject do
    build(:access_limit,
          users: users,
          organisations: organisations)
  end

  let(:users) { [SecureRandom.uuid] }
  let(:organisations) { [] }

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

  describe "validates organisation_ids" do
    context "where organisation_ids has an array with a uuids" do
      let(:organisations) { [SecureRandom.uuid, SecureRandom.uuid] }
      it { is_expected.to be_valid }
    end

    context "where users has an array with an integer" do
      let(:organisations) { [123] }
      it { is_expected.to be_invalid }
    end
  end
end
