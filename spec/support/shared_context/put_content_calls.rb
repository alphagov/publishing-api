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
end
