module Presenters
  class MessageQueuePresenter
    def self.present(downstream_presenter, update_type:)
      attributes = downstream_presenter.present
      attributes.merge(
        update_type: update_type,
        govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
      )
    end
  end
end
