module Presenters
  class MessageQueuePresenter
    def self.present(content_item, update_type:)
      attributes = DownstreamPresenter.present(content_item)
      attributes.merge(update_type: update_type)
    end
  end
end
