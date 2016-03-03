module Presenters
  class ContentStorePresenter
    def self.present(content_item, event)
      attributes = DownstreamPresenter.present(content_item, event)
      attributes.except(:update_type)
    end
  end
end
