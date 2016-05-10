module Commands
  class BaseCommand
    class <<self
      attr_accessor :callbacks

      def call(payload, downstream: true)
        logger.debug "#{self} called with payload:\n#{payload}"

        response = EventLogger.log_command(self, payload) do |event|
          new(payload, event: event, downstream: downstream).call
        end

        Array(callbacks).compact.each(&:call)

        response
      rescue ActiveRecord::RecordInvalid => e
        raise_validation_command_error(e)
      end
    end

    def initialize(payload, event:, downstream: true)
      @payload = payload
      @event = event
      @downstream = downstream
    end

  protected

    def after_transaction_commit
      self.class.callbacks = yield
    end

  private

    attr_reader :payload, :event, :downstream

    def self.raise_validation_command_error(e)
      errors = e.record.errors
      full_message = errors.full_messages.join(', ')

      raise CommandError.new(
        code: 422,
        message: full_message,
        error_details: {
          error: {
            code: 422,
            message: full_message,
            fields: errors.to_hash
          }
        }
      )
    end

    def check_version_and_raise_if_conflicting(current_versioned_item, previous_version_number)
      current_version = LockVersion.find_by(target: current_versioned_item)

      return unless current_versioned_item && current_version

      friendly_message = "A lock-version conflict occurred. The `previous_version` you've sent " +
        "(#{previous_version_number}) is not the same as the current " +
        "lock version of the content item (#{current_version.number})."

      fields = {
        fields: {
          previous_version: ["does not match"],
        },
      }

      if current_version.conflicts_with?(previous_version_number)
        raise_command_error(409, "Conflict", fields, friendly_message: friendly_message)
      end
    end

    def raise_command_error(code, message, fields, friendly_message: nil)
      raise CommandError.new(
        code: code,
        message: message,
        error_details: {
          error: {
            code: code,
            message: friendly_message || message,
          }.merge(fields)
        }
      )
    end
  end
end
