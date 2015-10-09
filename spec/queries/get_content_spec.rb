require "rails_helper"

RSpec.describe Queries::GetContent do
  before do
    FactoryGirl.create(:draft_content_item, content_id: "foo")
    FactoryGirl.create(:draft_content_item, content_id: "bar")
  end

  subject { described_class.new("foo") }

  it "returns the latest content item for a given content_id" do
    expect(subject.call.content_id).to eq("foo")
  end

  context "when the content item does not exist" do
    subject { described_class.new("missing") }

    it "returns an error object" do
      expect {
        subject.call
      }.to raise_error(CommandError, /with content_id: missing/)
    end
  end
end
