require "rails_helper"

RSpec.describe Queries::GetContentCollection do
  it "returns the content items of the given format" do
    create(:draft_content_item, :with_version, base_path: '/a', format: 'topic')
    create(:draft_content_item, :with_version, base_path: '/b',  format: 'topic')
    create(:draft_content_item, :with_version, base_path: '/c',  format: 'mainstream_browse_page')

    expect(Queries::GetContentCollection.new(
      content_format: 'topic',
      fields: ['base_path'],
    ).call).to eq([
      { "base_path" => "/a", "publication_state" => "draft" },
      { "base_path" => "/b", "publication_state" => "draft" },
    ])
  end

  it "returns the content items of the given format, and placeholder_format" do
    create(:draft_content_item, :with_version, base_path: '/a', format: 'topic')
    create(:draft_content_item, :with_version, base_path: '/b', format: 'placeholder_topic')

    expect(Queries::GetContentCollection.new(
      content_format: 'topic',
      fields: ['base_path'],
    ).call).to eq([
      { "base_path" => "/a", "publication_state" => "draft" },
      { "base_path" => "/b", "publication_state" => "draft" },
    ])
  end

  it "includes the publishing state of the item" do
    create(:draft_content_item, :with_version, base_path: '/draft', format: 'topic')
    create(:live_content_item, :with_version, :with_draft_version, base_path: '/live',  format: 'topic')

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

  context "filtering by publishing_app" do
    before do
      create(:draft_content_item, :with_version, base_path: '/a', format: 'topic', publishing_app: 'publisher')
      create(:draft_content_item, :with_version, base_path: '/b',  format: 'topic', publishing_app: 'publisher')
      create(:draft_content_item, :with_version, base_path: '/c',  format: 'topic', publishing_app: 'whitehall')
    end

    it "returns items corresponding to the publishing_app parameter if present" do
      expect(Queries::GetContentCollection.new(
        content_format: 'topic',
        fields: ['publishing_app'],
        publishing_app: 'publisher'
      ).call).to eq([
        { "publishing_app" => "publisher", "publication_state" => "draft" },
        { "publishing_app" => "publisher", "publication_state" => "draft" }
      ])
    end

    it "returns items for all apps if publishing_app is not present" do
      expect(Queries::GetContentCollection.new(
        content_format: 'topic',
        fields: ['publishing_app']
      ).call).to eq([
        { "publishing_app" => "publisher", "publication_state" => "draft" },
        { "publishing_app" => "publisher", "publication_state" => "draft" },
        { "publishing_app" => "whitehall", "publication_state" => "draft" }
      ])
    end
  end

  describe "pagination" do
    context "with multiple content items" do
      before do
        create(:draft_content_item, :with_version, base_path: '/a', format: 'topic')
        create(:draft_content_item, :with_version, base_path: '/b', format: 'topic')
        create(:draft_content_item, :with_version, base_path: '/c', format: 'topic')
        create(:draft_content_item, :with_version, base_path: '/d', format: 'topic')
        create(:live_content_item, :with_version, base_path: '/live1',  format: 'topic')
        create(:live_content_item, :with_version, base_path: '/live2',  format: 'topic')
      end

      it "limits the results returned" do
        content_items = Queries::GetContentCollection.new(
          content_format: 'topic',
          fields: ['publishing_app'],
          pagination: {
            start: 0,
            count: 3,
          }
        ).call

        expect(content_items.size).to eq(3)
      end

      it "fetches results from a specified index" do
        content_items = Queries::GetContentCollection.new(
          content_format: 'topic',
          fields: ['base_path'],
          pagination: {
            start: 1,
            count: 2,
          }
        ).call

        expect(content_items.first['base_path']).to eq('/b')
      end

      it "when count is higher than results we only receieve remaining content items" do
        content_items = Queries::GetContentCollection.new(
          content_format: 'topic',
          fields: ['base_path'],
          pagination: {
            start: 3,
            count: 8,
          }
        ).call

        expect(content_items.first['base_path']).to eq('/d')
        expect(content_items.last['base_path']).to eq('/live2')
      end

      it "returns both content item types up to the limit" do
        content_items = Queries::GetContentCollection.new(
          content_format: 'topic',
          fields: ['base_path'],
          pagination: {
            start: 0,
            count: 5,
          }
        ).call

        expect(content_items.first['base_path']).to eq('/a')
        expect(content_items.last['base_path']).to eq('/live1')
      end
    end
    context "with only live items" do
      before do
        create(:live_content_item, :with_version, base_path: '/live1',  format: 'topic')
        create(:live_content_item, :with_version, base_path: '/live2',  format: 'topic')
      end
      it "returns expected number of live items" do
        content_items = Queries::GetContentCollection.new(
          content_format: 'topic',
          fields: ['base_path'],
          pagination: {
            start: 2,
            count: 8,
          }
        ).call
        expect(content_items).to be_empty
      end
    end
  end
end
