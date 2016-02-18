require "rails_helper"

RSpec.describe "Superseding Content Items" do
  let(:put_content_command) { Commands::V2::PutContent }
  let(:publish_command) { Commands::V2::Publish }

  let(:content_id) { SecureRandom.uuid }

  let(:put_content_payload) do
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
      links: {},
    }
  end

  let(:publish_payload) do
    {
      content_id: content_id,
      update_type: "major",
    }
  end

  def call_commands
    put_content_command.call(put_content_payload)
    publish_command.call(publish_payload)
  end

  describe "after the first pair is called" do
    before { call_commands }

    it "creates and publishes a content item" do
      expect(ContentItem.count).to eq(1)

      content_item = ContentItem.first
      state = State.find_by!(content_item: content_item)

      expect(state.name).to eq("published")
    end

    describe "after the second pair is called" do
      before { call_commands }

      it "supersedes the previously published content item" do
        expect(ContentItem.count).to eq(2)

        superseded_content_item = ContentItem.first
        published_content_item = ContentItem.second

        superseded = State.find_by!(content_item: superseded_content_item)
        published = State.find_by!(content_item: published_content_item)

        expect(superseded.name).to eq("superseded")
        expect(published.name).to eq("published")
      end

      describe "after the third pair is called" do
        before { call_commands }

        it "supersedes the previously published content item (again)" do
          expect(ContentItem.count).to eq(3)

          superseded1_content_item = ContentItem.first
          superseded2_content_item = ContentItem.second
          published_content_item = ContentItem.third

          superseded1 = State.find_by!(content_item: superseded1_content_item)
          superseded2 = State.find_by!(content_item: superseded2_content_item)
          published = State.find_by!(content_item: published_content_item)

          expect(superseded1.name).to eq("superseded")
          expect(superseded2.name).to eq("superseded")
          expect(published.name).to eq("published")
        end
      end
    end
  end
end
