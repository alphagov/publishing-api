module RedirectHelper
  class Redirect
    attr_reader :previously_published_item, :previously_drafted_item, :payload, :callbacks

    def initialize(previously_published_item, previously_drafted_item, payload, callbacks)
      @previously_published_item = previously_published_item
      @previously_drafted_item = previously_drafted_item
      @payload = payload
      @callbacks = callbacks
    end

    def create
      return unless path_has_changed?

      redirect_payload = RedirectPresenter.new(
        base_path: previous_base_path,
        content_id: previous_content_id,
        locale: owning_document.locale,
        redirects: redirects_for(previous_routes, previous_base_path, payload[:base_path]),
        publishing_app: payload[:publishing_app],
      ).for_redirect_helper(SecureRandom.uuid)

      Commands::V2::PutContent.call(redirect_payload,
                                    callbacks: callbacks,
                                    nested: true,
                                    owning_document_id: owning_document.id)
    end

  private


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

    def previous_content_id
      previously_published_item.content_id ||
        previously_drafted_item.content_id
    end

    def redirects_for(routes, old_base_path, new_base_path)
      routes.map do |route|
        {
          path: route[:path],
          type: route[:type],
          destination: route[:path].gsub(old_base_path, new_base_path),
        }
      end
    end

    def owning_document
      previously_published_item.try(:document) ||
        previously_drafted_item.document
    end
  end
end
