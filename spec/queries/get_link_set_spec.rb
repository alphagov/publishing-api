require "rails_helper"

RSpec.describe Queries::GetLinkSet do
  before do
    FactoryGirl.create(:link_set, content_id: "foo")
    FactoryGirl.create(:link_set, content_id: "bar")
  end

  it "returns the link set for a given content_id" do
    expect(subject.call("foo").content_id).to eq("foo")
  end

  context "when the link set does not exist" do
    it "returns an error object" do
      expect {
        subject.call("missing")
      }.to raise_error(CommandError, /with content_id: missing/)
    end
  end
end
