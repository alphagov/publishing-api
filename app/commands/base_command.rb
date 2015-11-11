module Commands
  class BaseCommand
    def self.call(payload)
      self.new(payload).call
    rescue ActiveRecord::RecordInvalid => e
      raise_validation_command_error(e)
    end

    def initialize(payload)
      @payload = payload
    end

  private
    attr_reader :payload

    def base_path
      payload[:base_path]
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

    def validate_version_lock!(versioned_item_class, content_id, previous_version_number)
      current_versioned_item = versioned_item_class.find_by(content_id: content_id)
      current_version = Version.find_by(target: current_versioned_item)

      return unless current_versioned_item && current_version

      friendly_message = "A version conflict occurred. The version you've sent " +
        "(#{previous_version_number.inspect}) is not the same as the current " +
        "version of the content item (#{current_version.number.inspect})."

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
