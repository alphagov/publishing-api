RSpec.describe "Superseding editions" do
  let(:put_content_command) { Commands::V2::PutContent }
  let(:publish_command) { Commands::V2::Publish }

  let(:content_id) { SecureRandom.uuid }

  let(:put_content_payload) do
    {
      content_id:,
      base_path: "/vat-rates",
      title: "Some Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      document_type: "services_and_information",
      schema_name: "generic",
      details: {},
      locale: "en",
      routes: [{ path: "/vat-rates", type: "exact" }],
      redirects: [],
      phase: "beta",
    }
  end

  let(:publish_payload) do
    {
      content_id:,
      update_type: "major",
    }
  end

  def call_commands
    put_content_command.call(put_content_payload)
    publish_command.call(publish_payload)
  end

  describe "after the first pair is called" do
    before { call_commands }

    it "creates and publishes an edition" do
      expect(Edition.count).to eq(1)
      edition = Edition.first

      expect(edition.state).to eq("published")
      expect(edition.user_facing_version).to eq(1)
    end

    describe "after the second pair is called" do
      before { call_commands }

      it "supersedes the previously published edition" do
        expect(Edition.count).to eq(2)

        superseded_edition = Edition.first
        published_edition = Edition.second

        expect(superseded_edition.state).to eq("superseded")
        expect(published_edition.state).to eq("published")

        expect(superseded_edition.user_facing_version).to eq(1)
        expect(published_edition.user_facing_version).to eq(2)
      end

      describe "after the third pair is called" do
        before { call_commands }

        it "supersedes the previously published edition (again)" do
          expect(Edition.count).to eq(3)

          superseded1_edition = Edition.first
          superseded2_edition = Edition.second
          published_edition = Edition.third

          expect(superseded1_edition.state).to eq("superseded")
          expect(superseded2_edition.state).to eq("superseded")
          expect(published_edition.state).to eq("published")

          expect(superseded1_edition.user_facing_version).to eq(1)
          expect(superseded2_edition.user_facing_version).to eq(2)
          expect(published_edition.user_facing_version).to eq(3)
        end
      end
    end
  end
end
