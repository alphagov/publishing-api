require "rails_helper"

RSpec.describe Queries::GetLinked do
  before do
    FactoryGirl.create(:content_item_link, source: "foo", link_type: "organisations", target: "1111-1111-1111-1111")
    FactoryGirl.create(:content_item_link, source: "foo", link_type: "related-links", target: "2222-2222-2222-2222")
  end

  it "returns linked" do
    expect(subject.call("1111-1111-1111-1111", "organisations").map(&:source)).to eq(["foo"])
  end

  it "raises an error when no linked items are found" do
    expect {
      subject.call("1111-1111-1111-1111", "councils")
    }.to raise_error(CommandError)
  end
end
