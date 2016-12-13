require "rails_helper"

RSpec.describe "Unpublishing Content Items" do
  let(:put_content_command) { Commands::V2::PutContent }
  let(:publish_command) { Commands::V2::Publish }
  let(:unpublish_command) { Commands::V2::Unpublish }

  let(:content_id) { SecureRandom.uuid }

  let(:put_content_payload) do
    {
      content_id: content_id,
      base_path: "/vat-rates",
      title: "Some Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      document_type: "guide",
      schema_name: "guide",
      locale: "en",
      routes: [{ path: "/vat-rates", type: "exact" }],
      redirects: [],
      phase: "beta",
    }
  end

  let(:publish_payload) do
    {
      content_id: content_id,
      update_type: "major",
    }
  end

  let(:unpublish_payload) do
    {
      content_id: content_id,
      type: "gone",
    }
  end

  describe "after the first unpublishing" do
    before do
      put_content_command.call(put_content_payload)
      publish_command.call(publish_payload)
      unpublish_command.call(unpublish_payload)
    end

    it "unpublishes the content item" do
      content_items = ContentItem.where(content_id: content_id)
      expect(content_items.count).to eq(1)

      unpublished_item = content_items.last
      unpublished = State.find_by!(content_item: unpublished_item)

      expect(unpublished.name).to eq("unpublished")
    end

    describe "after the second unpublishing" do
      before do
        put_content_command.call(put_content_payload)
        publish_command.call(publish_payload)
        unpublish_command.call(unpublish_payload)
      end

      it "unpublishes the new content item and supersedes the old content item" do
        content_items = ContentItem.where(content_id: content_id)
        expect(content_items.count).to eq(2)

        superseded_item = content_items.first
        unpublished_item = content_items.last

        superseded = State.find_by!(content_item: superseded_item)
        unpublished = State.find_by!(content_item: unpublished_item)

        expect(superseded.name).to eq("superseded")
        expect(unpublished.name).to eq("unpublished")
      end
    end
  end
end
