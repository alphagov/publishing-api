module Commands
  class BaseCommand
    def self.call(payload, downstream: true)
      EventLogger.log_command(self, payload) do
        new(payload, downstream: downstream).call
      end
    rescue ActiveRecord::RecordInvalid => e
      raise_validation_command_error(e)
    end

    def initialize(payload, downstream: true)
      @payload = payload
      @downstream = downstream
    end

  private
    attr_reader :payload, :downstream

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
        "(#{previous_version_number.inspect}) is not the same as the current " +
        "lock version of the content item (#{current_version.number.inspect})."

      conflict_error = CommandError.new(
        code: 409,
        message: "Conflict",
        error_details: {
          error: {
            code: 409,
            message: friendly_message,
            fields: {
              previous_version: ["does not match"],
            }
          }
        }
      )

      raise conflict_error if current_version.conflicts_with?(previous_version_number)
    end
  end
end
