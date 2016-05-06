module Presenters
  class ContentStorePresenter
    def self.present(content_item, event, fallback_order:)
      attributes = DownstreamPresenter.present(content_item, fallback_order: fallback_order)
      attributes.except(:update_type).merge(payload_version: event.id)
    end
  end
end
