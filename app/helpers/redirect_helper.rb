module RedirectHelper
  extend self

  def create_redirect(old_base_path:, new_base_path:, publishing_app:, callbacks:, content_id: nil, routes: [])
    payload = RedirectPresenter.present(
      base_path: old_base_path,
      destination: new_base_path,
      public_updated_at: Time.zone.now,
      redirects: redirects_for(routes, old_base_path, new_base_path),
      publishing_app: publishing_app
    ).merge(content_id: content_id || SecureRandom.uuid)

    Commands::V2::PutContent.call(payload, callbacks: callbacks, nested: true)
  end

  def redirects_for(routes, old_base_path, new_base_path)
    routes.map do |route|
      {
        path: route[:path],
        type: route[:type],
        destination: route[:path].gsub(old_base_path, new_base_path)
      }
    end
  end

  class Redirect
    def initialize(previously_published_item, previously_drafted_item, payload, callbacks)
      @previously_published_item = previously_published_item
      @previously_drafted_item = previously_drafted_item
      @payload = payload
      @callbacks = callbacks
    end

    def create
      return unless path_has_changed?
      create_redirect(
        from_path: previous_base_path,
        to_path: payload[:base_path],
        routes: previous_routes,
      )
    end

  private

    attr_reader :previously_published_item, :previously_drafted_item, :payload, :callbacks

    def path_has_changed?
      previously_published_item.path_has_changed? ||
        previously_drafted_item_base_path_changed?
    end

    def previously_drafted_item_base_path_changed?
      return false unless previously_drafted_item
      previously_drafted_item.base_path != payload[:base_path]
    end

    def previous_routes
      previously_published_item.routes ||
        previously_drafted_item.routes
    end

    def previous_base_path
      previously_published_item.previous_base_path ||
        previously_drafted_item.base_path
    end

    def create_redirect(from_path:, to_path:, routes:)
      RedirectHelper.create_redirect(
        publishing_app: payload[:publishing_app],
        old_base_path: from_path,
        new_base_path: to_path,
        routes: routes,
        callbacks: callbacks,
      )
    end
  end
end
