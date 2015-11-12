module Presenters
  class ContentStorePresenter
    def self.present(content_item)
      attributes = DownstreamPresenter.present(content_item)
      attributes.except(:update_type)
    end
  end
end
