require "rails_helper"

RSpec.describe Query::GetContent do
  before do
    FactoryGirl.create(:draft_content_item, content_id: "foo")
    FactoryGirl.create(:draft_content_item, content_id: "bar")
  end

  subject { described_class.new("foo") }

  it "returns the latest content item for a given content_id" do
    expect(subject.call.content_id).to eq("foo")
  end
end
