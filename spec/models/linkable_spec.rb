require "rails_helper"

RSpec.describe Linkable do
  subject { FactoryGirl.build(:linkable) }

  it "is valid out of the factory" do
    expect(subject).to be_valid
  end

  it "requires a content item" do
    subject.content_item_id = nil
    expect(subject).not_to be_valid
  end

  it "requires a base_path" do
    subject.base_path = nil
    expect(subject).not_to be_valid
  end

  it "requires a unique base_path" do
    linkable = FactoryGirl.create(:linkable)

    subject.base_path = linkable.base_path
    expect(subject).not_to be_valid
  end

  it "requires a state" do
    subject.state = nil
    expect(subject).not_to be_valid
  end

  it "requires a document_type" do
    subject.document_type = nil
    expect(subject).not_to be_valid
  end
end
