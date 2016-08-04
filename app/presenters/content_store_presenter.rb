module Presenters
  class ContentStorePresenter
    def self.present(downstream_presenter, payload_version)
      attributes = downstream_presenter.present
      attributes.except(:update_type).merge(payload_version: payload_version)
    end
  end
end
