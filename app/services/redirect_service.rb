class RedirectService
  attr_reader :previously_published_item, :payload, :callbacks

  def initialize(previously_published_item, payload, callbacks)
    @previously_published_item = previously_published_item
    @payload = payload
    @callbacks = callbacks
  end

  def call
    return unless previously_published_item.path_has_changed?

    redirect_payload = RedirectPresenter.new(
      base_path: previously_published_item.previous_base_path,
      content_id: previously_published_item.content_id,
      locale: previously_published_item.document.locale,
      redirects: redirects_for(
        previously_published_item.routes,
        previously_published_item.previous_base_path,
        payload[:base_path],
      ),
      publishing_app: payload[:publishing_app],
    ).for_redirect_helper(SecureRandom.uuid)

    Commands::V2::PutContent.call(
      redirect_payload,
      callbacks: callbacks,
      nested: true,
      owning_document_id: previously_published_item.document.id,
    )
  end

private

  def redirects_for(routes, old_base_path, new_base_path)
    routes.map do |route|
      {
        path: route[:path],
        type: route[:type],
        destination: route[:path].gsub(old_base_path, new_base_path),
      }
    end
  end
end
