require "rails_helper"

RSpec.describe AccessLimit do
  subject do
    build(:access_limit,
          users: users,
          organisations: organisations,
          auth_bypass_ids: auth_bypass_ids)
  end

  let(:users) { [SecureRandom.uuid] }
  let(:organisations) { [] }
  let(:auth_bypass_ids) { [] }

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

  describe "validates auth_bypass_ids" do
    context "where auth_bypass_ids has an array with a uuids" do
      let(:auth_bypass_ids) { [SecureRandom.uuid, SecureRandom.uuid] }
      it { is_expected.to be_valid }
    end

    context "where auth_bypass_ids has an array with non uuids" do
      let(:auth_bypass_ids) { ["not-a-uuid"] }
      it { is_expected.to be_invalid }
    end

    context "where users has an array with an integer" do
      let(:auth_bypass_ids) { [123] }
      it { is_expected.to be_invalid }
    end
  end

  context "copys auth_bypass_ids to the edition" do
    it "when auth_bypass_ids are present" do
      auth_bypass_ids = [SecureRandom.uuid, SecureRandom.uuid]
      access_limit = create(:access_limit, auth_bypass_ids: auth_bypass_ids)
      expect(access_limit.edition.auth_bypass_ids).to eq(auth_bypass_ids)
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
