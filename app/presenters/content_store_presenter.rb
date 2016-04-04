module Presenters
  class ContentStorePresenter
    def self.present(content_item, event, fallback_order:)
      attributes = DownstreamPresenter.present(content_item, event, fallback_order: fallback_order)
      attributes.except(:update_type)
    end
  end
end
