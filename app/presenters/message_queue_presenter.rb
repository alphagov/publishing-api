module Presenters
  class MessageQueuePresenter
    def self.present(content_item, state_fallback_order:, update_type:)
      attributes = DownstreamPresenter.present(content_item, state_fallback_order: state_fallback_order)
      attributes.merge(
        update_type: update_type,
        govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
      )
    end
  end
end
