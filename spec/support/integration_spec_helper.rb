module IntegrationSpecHelper
  def default_payload
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

  def base_path
    "/vat-rates"
  end

  def locale
    "en"
  end

  def content_id
    @content_id ||= SecureRandom.uuid
  end

  def change_note
    { note: "Info", public_timestamp: Time.now.utc.to_s }
  end
end
