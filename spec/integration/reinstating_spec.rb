require "rails_helper"

RSpec.describe "Reinstating Content Items that were previously unpublished" do
  let(:put_content_command) { Commands::V2::PutContent }
  let(:publish_command) { Commands::V2::Publish }

  let(:guide_draft_payload) do
    {
      content_id: SecureRandom.uuid,
      base_path: '/vat-rates',
      title: "Guide Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      format: "guide",
      locale: "en",
      routes: [{ path: "/vat-rates", type: "exact" }],
      redirects: [],
      phase: "beta",
    }
  end

  let(:guide_publish_payload) do
    {
      content_id: guide_draft_payload.fetch(:content_id),
      update_type: "major",
    }
  end

  let(:redirect_draft_payload) do
    {
      content_id: SecureRandom.uuid,
      base_path: '/vat-rates',
      destination: "/somewhere",
      title: "Redirect Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      format: "redirect",
      locale: "en",
      routes: [],
      redirects: [{ path: "/vat-rates", type: "exact", destination: "/somewhere" }],
      phase: "beta",
    }
  end

  let(:redirect_publish_payload) do
    {
      content_id: redirect_draft_payload.fetch(:content_id),
      update_type: "major",
    }
  end

  describe "after the content item is unpublished" do
    before do
      2.times do
        put_content_command.call(guide_draft_payload)
        publish_command.call(guide_publish_payload)
      end

      put_content_command.call(redirect_draft_payload)
      publish_command.call(redirect_publish_payload)
    end

    it "puts the content items into the correct states and versions" do
      expect(ContentItem.count).to eq(3)

      superseded1_item = ContentItem.first
      superseded2_item = ContentItem.second
      published_item = ContentItem.third

      superseded1 = State.find_by!(content_item: superseded1_item)
      superseded2 = State.find_by!(content_item: superseded2_item)
      published = State.find_by!(content_item: published_item)

      expect(superseded1.name).to eq("superseded")
      expect(superseded2.name).to eq("unpublished")
      expect(published.name).to eq("published")

      superseded1_version = UserFacingVersion.find_by!(content_item: superseded1_item)
      superseded2_version = UserFacingVersion.find_by!(content_item: superseded2_item)
      published_version = UserFacingVersion.find_by!(content_item: published_item)

      expect(superseded1_version.number).to eq(1)
      expect(superseded2_version.number).to eq(2)
      expect(published_version.number).to eq(1),
        "The redirect should be regarded as a new piece of content"
    end

    describe "after the original content item has been reinstated" do
      before do
        put_content_command.call(guide_draft_payload)
        publish_command.call(guide_publish_payload)
      end

      it "puts the content items into the correct states and versions" do
        expect(ContentItem.count).to eq(4)

        superseded1_item = ContentItem.first
        superseded2_item = ContentItem.second
        unpublished_item = ContentItem.third
        published_item = ContentItem.fourth

        superseded1 = State.find_by!(content_item: superseded1_item)
        superseded2 = State.find_by!(content_item: superseded2_item)
        unpublished = State.find_by!(content_item: unpublished_item)
        published = State.find_by!(content_item: published_item)

        expect(superseded1.name).to eq("superseded")
        expect(superseded2.name).to eq("superseded")
        expect(unpublished.name).to eq("unpublished")
        expect(published.name).to eq("published")

        superseded1_version = UserFacingVersion.find_by!(content_item: superseded1_item)
        superseded2_version = UserFacingVersion.find_by!(content_item: superseded2_item)
        unpublished_version = UserFacingVersion.find_by!(content_item: unpublished_item)
        published_version = UserFacingVersion.find_by!(content_item: published_item)

        expect(superseded1_version.number).to eq(1)
        expect(superseded2_version.number).to eq(2)
        expect(unpublished_version.number).to eq(1)
        expect(published_version.number).to eq(3)
      end

      describe "after the original content item has been superseded (again)" do
        before do
          put_content_command.call(guide_draft_payload)
          publish_command.call(guide_publish_payload)
        end

        it "puts the content items into the correct states and versions" do
          expect(ContentItem.count).to eq(5)

          superseded1_item = ContentItem.first
          superseded2_item = ContentItem.second
          unpublished_item = ContentItem.third
          superseded3_item = ContentItem.fourth
          published_item = ContentItem.fifth

          superseded1 = State.find_by!(content_item: superseded1_item)
          superseded2 = State.find_by!(content_item: superseded2_item)
          unpublished = State.find_by!(content_item: unpublished_item)
          superseded3 = State.find_by!(content_item: superseded3_item)
          published = State.find_by!(content_item: published_item)

          expect(superseded1.name).to eq("superseded")
          expect(superseded2.name).to eq("superseded")
          expect(unpublished.name).to eq("unpublished")
          expect(superseded3.name).to eq("superseded")
          expect(published.name).to eq("published")

          superseded1_version = UserFacingVersion.find_by!(content_item: superseded1_item)
          superseded2_version = UserFacingVersion.find_by!(content_item: superseded2_item)
          unpublished_version = UserFacingVersion.find_by!(content_item: unpublished_item)
          superseded3_version = UserFacingVersion.find_by!(content_item: superseded3_item)
          published_version = UserFacingVersion.find_by!(content_item: published_item)

          expect(superseded1_version.number).to eq(1)
          expect(superseded2_version.number).to eq(2)
          expect(unpublished_version.number).to eq(1)
          expect(superseded3_version.number).to eq(3)
          expect(published_version.number).to eq(4)
        end
      end
    end
  end
end
