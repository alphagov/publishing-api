module Presenters
  class ContentStorePresenter
    def self.present(content_item, payload_version, state_fallback_order:)
      attributes = DownstreamPresenter.present(content_item, state_fallback_order: state_fallback_order)
      attributes.except(:update_type).merge(payload_version: payload_version)
    end
  end
end
