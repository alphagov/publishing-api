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

  def call_commands
    put_content_command.call(put_content_payload)
    publish_command.call(publish_payload)
  end

  describe "after the first pair is called" do
    before { call_commands }

    it "creates and publishes a content item" do
      expect(Edition.count).to eq(1)
      content_item = Edition.first

      expect(content_item.state).to eq("published")
      expect(content_item.user_facing_version).to eq(1)
    end

    describe "after the second pair is called" do
      before { call_commands }

      it "supersedes the previously published content item" do
        expect(Edition.count).to eq(2)

        superseded_content_item = Edition.first
        published_content_item = Edition.second

        expect(superseded_content_item.state).to eq("superseded")
        expect(published_content_item.state).to eq("published")

        expect(superseded_content_item.user_facing_version).to eq(1)
        expect(published_content_item.user_facing_version).to eq(2)
      end

      describe "after the third pair is called" do
        before { call_commands }

        it "supersedes the previously published content item (again)" do
          expect(Edition.count).to eq(3)

          superseded1_content_item = Edition.first
          superseded2_content_item = Edition.second
          published_content_item = Edition.third

          expect(superseded1_content_item.state).to eq("superseded")
          expect(superseded2_content_item.state).to eq("superseded")
          expect(published_content_item.state).to eq("published")

          expect(superseded1_content_item.user_facing_version).to eq(1)
          expect(superseded2_content_item.user_facing_version).to eq(2)
          expect(published_content_item.user_facing_version).to eq(3)
        end
      end
    end
  end
end
