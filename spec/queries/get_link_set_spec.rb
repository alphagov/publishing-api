require "rails_helper"

RSpec.describe Queries::GetLinkSet do
  before do
    foo = FactoryGirl.create(:link_set, content_id: "foo")
    FactoryGirl.create(:version, target: foo, number: 2)
    FactoryGirl.create(:link_set, content_id: "bar")
  end

  it "returns the link set for a given content_id" do
    expect(subject.call("foo").fetch(:content_id)).to eq("foo")
  end

  it "returns the version of the link set" do
    expect(subject.call("foo").fetch(:version)).to eq(2)
  end

  context "when the link set does not exist" do
    it "returns an error object" do
      expect {
        subject.call("missing")
      }.to raise_error(CommandError, /with content_id: missing/)
    end
  end
end
