require "rails_helper"

RSpec.describe Queries::GetContent do
  let(:content_id) { SecureRandom.uuid }
  let(:locale) { nil }

  before do
    FactoryGirl.create(
      :live_content_item,
      :with_translation,
      :with_location,
      :with_semantic_version,
      :with_version,
      content_id: content_id,
      semantic_version: 2,
      title: "foo",
    )

    FactoryGirl.create(
      :draft_content_item,
      :with_translation,
      :with_location,
      :with_semantic_version,
      :with_version,
      content_id: content_id,
      semantic_version: 3,
      title: "bar",
    )

    FactoryGirl.create(
      :content_item,
      :with_state,
      :with_translation,
      :with_location,
      :with_semantic_version,
      :with_version,
      content_id: content_id,
      semantic_version: 4,
      state: "archived",
      title: "baz",
    )
  end

  it "presents the latest 'draft' or 'live' content item" do
    result = subject.call(content_id, locale)
    expect(result.fetch(:title)).to eq("bar")
  end

  context "when no content item exists for the content_id" do
    it "raises a command error" do
      expect {
        subject.call("missing", locale)
      }.to raise_error(CommandError, /with content_id: missing/)
    end
  end

  context "when a locale is specified" do
    let(:locale) { "fr" }

    before do
      french_draft = FactoryGirl.create(
        :draft_content_item,
        :with_translation,
        :with_location,
        :with_semantic_version,
        :with_version,
        content_id: content_id,
        locale: "fr",
        title: "qux",
      )
    end

    it "returns the content item in the specified locale" do
      result = subject.call(content_id, locale)

      expect(result.fetch(:title)).to eq("qux")
      expect(result.fetch(:locale)).to eq("fr")
    end
  end
end
