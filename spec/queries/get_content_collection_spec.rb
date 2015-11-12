require "rails_helper"

RSpec.describe Queries::GetContentCollection do
  it "returns the content items of the given format" do
    create(:draft_content_item, base_path: '/a', format: 'topic')
    create(:draft_content_item, base_path: '/b',  format: 'topic')
    create(:draft_content_item, base_path: '/c',  format: 'mainstream_browse_page')

    expect(Queries::GetContentCollection.new(
      content_format: 'topic',
      fields: ['base_path'],
    ).call).to eq([
      { "base_path" => "/a", "publication_state" => "draft" },
      { "base_path" => "/b", "publication_state" => "draft" },
    ])
  end

  it "returns the content items of the given format, and placeholder_format" do
    create(:draft_content_item, base_path: '/a', format: 'topic')
    create(:draft_content_item, base_path: '/b', format: 'placeholder_topic')

    expect(Queries::GetContentCollection.new(
      content_format: 'topic',
      fields: ['base_path'],
    ).call).to eq([
      { "base_path" => "/a", "publication_state" => "draft" },
      { "base_path" => "/b", "publication_state" => "draft" },
    ])
  end

  it "includes the publishing state of the item" do
    create(:draft_content_item, base_path: '/draft', format: 'topic')
    item = create(:live_content_item, base_path: '/live',  format: 'topic')

    expect(Queries::GetContentCollection.new(
      content_format: 'topic',
      fields: ['base_path'],
    ).call).to eq([
      { "base_path" => "/draft", "publication_state" => "draft"},
      { "base_path" => "/live", "publication_state" => "live" },
    ])
  end

  context "when there's no items for the format" do
    it "returns an empty array" do
      expect(Queries::GetContentCollection.new(
        content_format: 'topic',
        fields: ['base_path'],
      ).call).to eq([])
    end
  end

  context "when unknown fields are requested" do
    it "raises an error" do
      expect {
        Queries::GetContentCollection.new(
          content_format: 'topic',
          fields: ['not_existing'],
        ).call
      }.to raise_error(CommandError)
    end
  end
end
