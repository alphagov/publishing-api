module Presenters
  class MessageQueuePresenter
    def self.present(content_item, event, update_type:)
      attributes = DownstreamPresenter.present(content_item, event)
      attributes.merge(update_type: update_type)
    end
  end
end
