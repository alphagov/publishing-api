module RedirectHelper
  def self.create_redirect(old_base_path:, new_base_path:, publishing_app:, content_id: nil, locale: "en")
    Commands::V2::PutContent.call(
      content_id: content_id || SecureRandom.uuid,
      base_path: old_base_path,
      locale: locale,
      format: 'redirect',
      public_updated_at: Time.zone.now,
      redirects: [{
        path: old_base_path,
        type: "exact",
        destination: new_base_path,
      }],
      publishing_app: publishing_app
    )
  end
end
