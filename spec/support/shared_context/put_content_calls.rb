RSpec.shared_context "PutContent call" do
  let(:payload) do
    {
      content_id: content_id,
      base_path: base_path,
      update_type: "major",
      title: "Some Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      document_type: "nonexistent-schema",
      schema_name: "nonexistent-schema",
      locale: locale,
      routes: [{ path: base_path, type: "exact" }],
      redirects: [],
      phase: "beta",
      change_note: change_note
    }
  end

  let(:base_path) { "/vat-rates" }
  let(:locale) { "en" }
  let(:content_id) { SecureRandom.uuid }

  let(:change_note) do
    { note: "Info", public_timestamp: Time.now.utc.to_s }
  end
end
