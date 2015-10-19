module EventLogger
  def self.log_command(command_class, payload, &block)
    tries = 3
    begin
      response = nil

      Event.connection.transaction do
        Event.create!(
          action: action(command_class),
          payload: payload,
          user_uid: GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user]
        )

        response = yield if block_given?
      end

      response
    rescue CommandRetryableError => e
      if (tries -= 1) > 0
        retry
      else
        raise CommandError.new(code: 500, message: "Too many retries - #{e.message}")
      end
    end
  end

private
  def self.action(command_class)
    command_class.name.split("::")[-1]
  end
end
