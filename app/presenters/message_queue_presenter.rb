module Presenters
  class MessageQueuePresenter
    attr_reader :edition, :draft, :notification_attributes, :edition_presenter

    def initialize(edition, draft: false, notification_attributes: {})
      @edition = edition
      @draft = draft
      @notification_attributes = notification_attributes
      @edition_presenter = EditionPresenter.new(edition, draft: draft)
    end

    def for_message_queue(payload_version)
      edition_presenter.for_message_queue(payload_version)
        .merge(presented_publishing_app)
        .merge(presented_workflow_message)
    end

  private

    def presented_workflow_message
      return {} unless notification_attributes[:workflow_message].present?

      { workflow_message: notification_attributes[:workflow_message] }
    end

    def presented_publishing_app
      return {} unless notification_attributes[:publishing_app].present?

      { publishing_app: notification_attributes[:publishing_app] }
    end
  end
end
