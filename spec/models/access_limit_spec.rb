require "rails_helper"

RSpec.describe AccessLimit do
  subject { FactoryGirl.build(:access_limit) }

  it "validates that user UIDs are strings" do
    subject.users << "a-string-uuid"
    expect(subject).to be_valid

    subject.users << 123
    expect(subject).not_to be_valid
  end
end
