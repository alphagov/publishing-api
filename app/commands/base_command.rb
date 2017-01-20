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

    def after_transaction_commit(&block)
      callbacks << block
    end

    def self.execute_callbacks(callbacks)
      callbacks.each(&:call)
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
    private_class_method :execute_callbacks, :raise_validation_command_error

    def check_version_and_raise_if_conflicting(current_versioned_item, previous_version)
      return unless current_versioned_item && previous_version.present?

      current_version = current_versioned_item.stale_lock_version

      if current_version != previous_version.to_i
        friendly_message = "A lock-version conflict occurred. The " +
          "`previous_version` you've sent (#{previous_version}) is not the " +
          "same as the current lock version of the content item " +
          "(#{current_version})."

        fields = {
          fields: {
            previous_version: ["does not match"],
          },
        }

        raise_command_error(409, "Conflict", fields, friendly_message: friendly_message)
      end

      current_version
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
