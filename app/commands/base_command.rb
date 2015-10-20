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
      full_message = errors.full_messages.join

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
  end
end
