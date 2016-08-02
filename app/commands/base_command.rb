module Commands
  class BaseCommand
    attr_reader :callbacks

    def self.call(payload, downstream: true, nested: false, callbacks: [])
      logger.debug "#{self} called with payload:\n#{payload}"

      response = EventLogger.log_command(self, payload) do |event|
        PublishingAPI.service(:statsd).time(self.name.gsub(/:+/, '.')) do
          new(payload, event: event, downstream: downstream, callbacks: callbacks, nested: nested).call
        end
      end

      execute_callbacks(callbacks) unless nested

      response
    rescue ActiveRecord::RecordInvalid => e
      raise_validation_command_error(e)
    end

    def initialize(payload, event:, downstream: true, nested: false, callbacks:)
      @payload = payload
      @event = event
      @downstream = downstream
      @nested = nested
      @callbacks = callbacks
    end

  private

    attr_reader :payload, :event, :downstream, :nested

    def self.execute_callbacks(callbacks)
      callbacks.each(&:call)
    end

    def after_transaction_commit(&block)
      callbacks << block
    end

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

      if current_version.conflicts_with?(previous_version_number)
        friendly_message = "A lock-version conflict occurred. The `previous_version` you've sent " +
          "(#{previous_version_number}) is not the same as the current " +
          "lock version of the content item (#{current_version.number})."

        fields = {
          fields: {
            previous_version: ["does not match"],
          },
        }

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
