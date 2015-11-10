require "rails_helper"

RSpec.describe Queries::GetContent do
  let(:foo) { SecureRandom.uuid }
  let(:bar) { SecureRandom.uuid }

  before do
    draft = FactoryGirl.create(:draft_content_item, content_id: foo, base_path: "/foo")
    FactoryGirl.create(:version, target: draft, number: 3)
    FactoryGirl.create(:draft_content_item, content_id: bar, base_path: "/bar")
  end

  it "returns the latest content item for a given content_id" do
    expect(subject.call(foo).fetch(:content_id)).to eq(foo)
  end

  it "returns the content version for a given content_id" do
    expect(subject.call(foo).fetch(:version)).to eq(3)
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
      arabic_draft = FactoryGirl.create(:draft_content_item, content_id: foo, locale: "ar", base_path: "/foo.ar")
      FactoryGirl.create(:version, target: arabic_draft, number: 3)
    end

    it "returns the content item in the specified locale" do
      expect(subject.call(foo).fetch(:locale)).to eq("en")
      expect(subject.call(foo, "ar").fetch(:locale)).to eq("ar")
    end
  end
end
