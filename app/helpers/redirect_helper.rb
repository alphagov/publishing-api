module RedirectHelper
  def self.create_redirect(old_base_path:, new_base_path:, publishing_app:, callbacks:, content_id: nil, routes: [], options: {})
    payload = RedirectPresenter.present(
      base_path: old_base_path,
      destination: new_base_path,
      public_updated_at: Time.zone.now,
      redirects: redirects_for(routes, old_base_path, new_base_path),
      publishing_app: publishing_app
    ).merge(content_id: content_id || SecureRandom.uuid)

    Commands::V2::PutContent.call(payload, callbacks: callbacks, nested: true) unless options[:skip_put_content]
    payload
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
