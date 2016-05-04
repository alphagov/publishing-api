module Presenters
  class MessageQueuePresenter
    def self.present(content_item, fallback_order:, update_type:)
      attributes = DownstreamPresenter.present(content_item, fallback_order: fallback_order)
      attributes.merge(
        update_type: update_type,
        govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
      )
    end
  end
end
