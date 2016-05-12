module RedirectHelper
  def self.create_redirect(old_base_path:, new_base_path:, publishing_app:, callbacks:, content_id: nil, locale: "en", routes: [])
    payload = {
      content_id: content_id || SecureRandom.uuid,
      base_path: old_base_path,
      locale: locale,
      format: 'redirect',
      public_updated_at: Time.zone.now,
      redirects: redirects_for(routes, old_base_path, new_base_path),
      publishing_app: publishing_app
    }

    Commands::V2::PutContent.call(payload, callbacks: callbacks, nested: true)
  end

  def self.redirects_for(routes, old_base_path, new_base_path)
    routes.map do |route|
      {
        path: route[:path],
        type: route[:type],
        destination: route[:path].gsub(old_base_path, new_base_path)
      }
    end
  end
end
