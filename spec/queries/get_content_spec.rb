require "rails_helper"

RSpec.describe Queries::GetContent do
  before do
    FactoryGirl.create(:draft_content_item, content_id: "foo")
    FactoryGirl.create(:draft_content_item, content_id: "bar")
  end

  it "returns the latest content item for a given content_id" do
    expect(subject.call("foo").content_id).to eq("foo")
  end

  context "when the content item does not exist" do
    it "returns an error object" do
      expect {
        subject.call("missing")
      }.to raise_error(CommandError, /with content_id: missing/)
    end
  end

  context "when a locale is specified" do
    before do
      FactoryGirl.create(:draft_content_item, content_id: "foo", locale: "ar")
    end

    it "returns the content item in the specified locale" do
      expect(subject.call("foo").locale).to eq("en")
      expect(subject.call("foo", "ar").locale).to eq("ar")
    end
  end
end
