module Commands
  module V2
    class Notify < BaseCommand
      def call
        @payload_version = Event.maximum_id

        validate

        send_downstream

        Success.new(content_id: document.content_id)
      end

    private

      attr_reader :payload_version

      def validate
        check_workflow_message_and_raise_unless_present
        check_document_and_raise_if_not_exists
        check_edition_and_raise_if_not_published
        check_version_and_raise_if_conflicting(document, previous_version_number)
      end

      def send_downstream
        downstream_payload = DownstreamPayload.new(
          edition,
          payload_version,
          draft: false,
          workflow_message: payload[:workflow_message],
        )
        DownstreamService.broadcast_to_message_queue(downstream_payload, "workflow")
      end

      def document
        @document ||= Document.find_by(
          content_id: payload[:content_id],
          locale: payload.fetch(:locale, Edition::DEFAULT_LOCALE),
        )
      end

      def edition
        @edition ||= document.live
      end

      def previous_version_number
        payload[:previous_version].to_i if payload[:previous_version]
      end

      def check_document_and_raise_if_not_exists
        unless document
          fields = { fields: { content_id: ["must be valid"] } }
          friendly_message = "Notifications can only be sent for valid content."
          raise_command_error(404, "Not found", fields, friendly_message: friendly_message)
        end
      end

      def check_edition_and_raise_if_not_published
        unless edition
          fields = { fields: { content_id: ["must be published"] } }
          friendly_message = "Notifications can only be sent for published editions."
          raise_command_error(422, "Unprocessable entity", fields, friendly_message: friendly_message)
        end
      end

      def check_workflow_message_and_raise_unless_present
        unless payload[:workflow_message]
          friendly_message = <<-MSG.strip_heredoc
            Please provide a workflow message for this notification.
            The workflow message is used to explain why the notification has been sent to the user.
          MSG

          fields = {
            fields: {
              workflow_message: ["must be present"],
            },
          }
          raise_command_error(422, "Unprocessable entity", fields, friendly_message: friendly_message)
        end
      end
    end
  end
end
