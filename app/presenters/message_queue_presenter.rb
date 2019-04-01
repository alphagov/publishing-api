module Presenters
  class MessageQueuePresenter
    attr_reader :edition, :draft, :workflow_message, :edition_presenter

    def initialize(edition, draft: false, workflow_message: nil)
      @edition = edition
      @draft = draft
      @workflow_message = workflow_message
      @edition_presenter = EditionPresenter.new(edition, draft: draft)
    end

    def for_message_queue(payload_version)
      edition_presenter.for_message_queue(payload_version)
        .merge(presented_workflow_message)
    end

  private

    def presented_workflow_message
      return {} unless workflow_message

      { workflow_message: workflow_message }
    end
  end
end
