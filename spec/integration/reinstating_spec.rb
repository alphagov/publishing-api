require "rails_helper"

RSpec.describe "Reinstating Content Items that were previously withdrawn" do
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

  describe "after the content item is withdrawn" do
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

      superseded_item = ContentItem.first
      withdrawn_item = ContentItem.second
      published_item = ContentItem.third

      superseded = State.find_by!(content_item: superseded_item)
      withdrawn = State.find_by!(content_item: withdrawn_item)
      published = State.find_by!(content_item: published_item)

      expect(superseded.name).to eq("superseded")
      expect(withdrawn.name).to eq("withdrawn")
      expect(published.name).to eq("published")

      superseded_version = UserFacingVersion.find_by!(content_item: superseded_item)
      withdrawn_version = UserFacingVersion.find_by!(content_item: withdrawn_item)
      published_version = UserFacingVersion.find_by!(content_item: published_item)

      expect(superseded_version.number).to eq(1)
      expect(withdrawn_version.number).to eq(2)
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

        superseded_item = ContentItem.first
        withdrawn1_item = ContentItem.second
        withdrawn2_item = ContentItem.third
        published_item = ContentItem.fourth

        superseded = State.find_by!(content_item: superseded_item)
        withdrawn1 = State.find_by!(content_item: withdrawn1_item)
        withdrawn2 = State.find_by!(content_item: withdrawn2_item)
        published = State.find_by!(content_item: published_item)

        expect(superseded.name).to eq("superseded")
        expect(withdrawn1.name).to eq("withdrawn")
        expect(withdrawn2.name).to eq("withdrawn")
        expect(published.name).to eq("published")

        superseded_version = UserFacingVersion.find_by!(content_item: superseded_item)
        withdrawn1_version = UserFacingVersion.find_by!(content_item: withdrawn1_item)
        withdrawn2_version = UserFacingVersion.find_by!(content_item: withdrawn2_item)
        published_version = UserFacingVersion.find_by!(content_item: published_item)

        expect(superseded_version.number).to eq(1)
        expect(withdrawn1_version.number).to eq(2)
        expect(withdrawn2_version.number).to eq(1)
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
          withdrawn1_item = ContentItem.second
          withdrawn2_item = ContentItem.third
          superseded2_item = ContentItem.fourth
          published_item = ContentItem.fifth

          superseded1 = State.find_by!(content_item: superseded1_item)
          withdrawn1 = State.find_by!(content_item: withdrawn1_item)
          withdrawn2 = State.find_by!(content_item: withdrawn2_item)
          superseded2 = State.find_by!(content_item: superseded2_item)
          published = State.find_by!(content_item: published_item)

          expect(superseded1.name).to eq("superseded")
          expect(withdrawn1.name).to eq("withdrawn")
          expect(withdrawn2.name).to eq("withdrawn")
          expect(superseded2.name).to eq("superseded")
          expect(published.name).to eq("published")

          superseded1_version = UserFacingVersion.find_by!(content_item: superseded1_item)
          withdrawn1_version = UserFacingVersion.find_by!(content_item: withdrawn1_item)
          withdrawn2_version = UserFacingVersion.find_by!(content_item: withdrawn2_item)
          superseded2_version = UserFacingVersion.find_by!(content_item: superseded2_item)
          published_version = UserFacingVersion.find_by!(content_item: published_item)

          expect(superseded1_version.number).to eq(1)
          expect(withdrawn1_version.number).to eq(2)
          expect(withdrawn2_version.number).to eq(1)
          expect(superseded2_version.number).to eq(3)
          expect(published_version.number).to eq(4)
        end
      end
    end
  end
end
