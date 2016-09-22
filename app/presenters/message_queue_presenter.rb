module Presenters
  class MessageQueuePresenter
    def self.present(downstream_presenter, update_type:)
      attributes = downstream_presenter.present
      # FIXME: This only happens in tests. We need to fix the tests so that
      # `link_set` is always available.
      if downstream_presenter.link_set
        links = Presenters::Queries::LinkSetPresenter.new(downstream_presenter.link_set).links
      else
        links = {}
      end

      attributes.merge(
        update_type: update_type,
        govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
        links: links
      )
    end
  end
end
