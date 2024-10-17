RSpec.shared_context "PutContent call" do
  let(:payload) do
    {
      content_id:,
      base_path:,
      update_type: "major",
      title: "Some Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      document_type: "services_and_information",
      schema_name: "generic",
      details: {},
      locale:,
      routes: [{ path: base_path, type: "exact" }],
      redirects: [],
      phase: "beta",
      change_note:,
    }
  end

  let(:base_path) { "/vat-rates" }
  let(:locale) { "en" }
  let(:content_id) { SecureRandom.uuid }
  let(:change_note) { "change note" }

  shared_examples "setting last_edited_by_editor_id" do
    context "when last_edited_by_editor_id is present in the payload" do
      let(:last_edited_by_editor_id) { SecureRandom.uuid }
      before do
        payload.merge!(
          last_edited_by_editor_id:,
        )
      end

      it "adds a last_edited_by_editor_id to the edition" do
        put "/v2/content/#{content_id}", params: payload.to_json

        expect(subject.last_edited_by_editor_id).to eq(last_edited_by_editor_id)
      end
    end

    it "does not set a last_edited_by_editor_id by default" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect(subject.last_edited_by_editor_id).to be_nil
    end
  end
end
