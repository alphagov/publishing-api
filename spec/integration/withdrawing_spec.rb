require "rails_helper"

RSpec.describe "Withdrawing Content Items" do
  let(:put_content_command) { Commands::V2::PutContent }

  let(:content_id) { SecureRandom.uuid }
  let(:another_content_id) { SecureRandom.uuid }

  let(:guide_payload) do
    {
      content_id: content_id,
      base_path: "/vat-rates",
      title: "Some Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      format: "guide",
      locale: "en",
      routes: [{ path: "/vat-rates", type: "exact" }],
      redirects: [],
      phase: "beta",
    }
  end

  let(:gone_payload) do
    {
      content_id: another_content_id,
      base_path: "/vat-rates",
      format: "gone",
      publishing_app: "publisher",
      routes: [{ path: "/vat-rates", type: "exact" }],
    }
  end

  describe "after the first unpublishing" do
    before do
      put_content_command.call(guide_payload)
      put_content_command.call(gone_payload)
    end

    it "unpublishes the previous draft content item" do
      expect(ContentItem.count).to eq(2)

      unpublished_item = ContentItem.first
      draft_item = ContentItem.second

      unpublished = State.find_by!(content_item: unpublished_item)
      draft = State.find_by!(content_item: draft_item)

      expect(unpublished.name).to eq("unpublished")
      expect(draft.name).to eq("draft")
    end

    describe "after the second unpublishing" do
      before do
        put_content_command.call(guide_payload)
      end

      it "unpublishes the second draft content item" do
        expect(ContentItem.count).to eq(3)

        unpublished1_item = ContentItem.first
        unpublished2_item = ContentItem.second
        draft_item = ContentItem.third

        unpublished1 = State.find_by!(content_item: unpublished1_item)
        unpublished2 = State.find_by!(content_item: unpublished2_item)
        draft = State.find_by!(content_item: draft_item)

        expect(unpublished1.name).to eq("unpublished")
        expect(unpublished2.name).to eq("unpublished")
        expect(draft.name).to eq("draft")
      end
    end
  end
end
