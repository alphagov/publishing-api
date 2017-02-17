module RedirectPresenter
  def self.present(base_path:, publishing_app:, public_updated_at:, redirects:)
    {
      document_type: "redirect",
      schema_name: "redirect",
      base_path: base_path,
      publishing_app: publishing_app,
      public_updated_at: public_updated_at.iso8601,
      redirects: redirects,
    }
  end
end
