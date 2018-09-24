require "rails_helper"

RSpec.describe "Redirecting editions that are redrafted" do
  let(:put_content) { Commands::V2::PutContent }
  let(:publish) { Commands::V2::Publish }

  let(:draft_payload) do
    {
      content_id: SecureRandom.uuid,
      base_path: "/foo",
      title: "Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      schema_name: "generic",
      document_type: "services_and_information",
      details: {},
      routes: [{ path: "/foo", type: "exact" }],
    }
  end

  let(:moved_payload) do
    draft_payload.merge(
      base_path: "/bar",
      routes: [{ path: "/bar", type: "exact" }],
    )
  end

  let(:publish_payload) do
    {
      content_id: draft_payload.fetch(:content_id),
      update_type: "major",
    }
  end

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  context "when a published item's base path is updated" do
    before do
      put_content.call(draft_payload)
      publish.call(publish_payload)
      put_content.call(moved_payload)
    end

    it "sets up the editions in the expected initial state" do
      expect(Edition.count).to eq(3)

      edition = Edition.first
      expect(edition.schema_name).to eq("generic")
      expect(edition.state).to eq("published")
      expect(edition.base_path).to eq("/foo")
      expect(edition.user_facing_version).to eq(1)

      edition = Edition.second
      expect(edition.schema_name).to eq("generic")
      expect(edition.state).to eq("draft")
      expect(edition.base_path).to eq("/bar")
      expect(edition.user_facing_version).to eq(2)

      edition = Edition.third
      expect(edition.schema_name).to eq("redirect")
      expect(edition.state).to eq("draft")
      expect(edition.base_path).to eq("/foo")
      expect(edition.user_facing_version).to eq(1)
    end

    context "when the item is published" do
      before do
        publish.call(publish_payload)
      end

      it "transitions the states of the editions correctly" do
        expect(Edition.count).to eq(3)

        edition = Edition.first
        expect(edition.schema_name).to eq("generic")
        expect(edition.state).to eq("superseded")
        expect(edition.base_path).to eq("/foo")
        expect(edition.user_facing_version).to eq(1)

        edition = Edition.second
        expect(edition.schema_name).to eq("generic")
        expect(edition.state).to eq("published")
        expect(edition.base_path).to eq("/bar")
        expect(edition.user_facing_version).to eq(2)

        edition = Edition.third
        expect(edition.schema_name).to eq("redirect")
        expect(edition.state).to eq("published")
        expect(edition.base_path).to eq("/foo")
        expect(edition.user_facing_version).to eq(1)
      end
    end
  end

  context "when a redrafted item's base path is updated" do
    before do
      put_content.call(draft_payload)
      publish.call(publish_payload)
      put_content.call(draft_payload)
      put_content.call(moved_payload)
    end

    it "sets up the editions in the expected initial state" do
      expect(Edition.count).to eq(3)

      edition = Edition.first
      expect(edition.schema_name).to eq("generic")
      expect(edition.state).to eq("published")
      expect(edition.base_path).to eq("/foo")
      expect(edition.user_facing_version).to eq(1)

      edition = Edition.second
      expect(edition.schema_name).to eq("generic")
      expect(edition.state).to eq("draft")
      expect(edition.base_path).to eq("/bar")
      expect(edition.user_facing_version).to eq(2)

      edition = Edition.third
      expect(edition.schema_name).to eq("redirect")
      expect(edition.state).to eq("draft")
      expect(edition.base_path).to eq("/foo")
      expect(edition.user_facing_version).to eq(1)
    end

    context "when the redrafted item is published" do
      before do
        publish.call(publish_payload)
      end

      it "transitions the states of the editions correctly" do
        expect(Edition.count).to eq(3)

        edition = Edition.first
        expect(edition.schema_name).to eq("generic")
        expect(edition.state).to eq("superseded")
        expect(edition.base_path).to eq("/foo")
        expect(edition.user_facing_version).to eq(1)

        edition = Edition.second
        expect(edition.schema_name).to eq("generic")
        expect(edition.state).to eq("published")
        expect(edition.base_path).to eq("/bar")
        expect(edition.user_facing_version).to eq(2)

        edition = Edition.third
        expect(edition.schema_name).to eq("redirect")
        expect(edition.state).to eq("published")
        expect(edition.base_path).to eq("/foo")
        expect(edition.user_facing_version).to eq(1)
      end

      it "does not raise an error on subsequent redrafts and publishes" do
        expect {
          put_content.call(draft_payload)
          publish.call(publish_payload)
        }.not_to raise_error

        expect {
          put_content.call(draft_payload)
          publish.call(publish_payload)
        }.not_to raise_error
      end
    end
  end
end
