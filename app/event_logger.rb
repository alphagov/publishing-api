module EventLogger
  def self.log_command(command_class, payload, &_block)
    tries = 5
    begin
      response = nil

      Event.connection.transaction do
        event = Event.create!(
          content_id: payload[:content_id],
          action: action(command_class),
          payload: payload,
          user_uid: GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user],
          request_id: GdsApi::GovukHeaders.headers[:govuk_request_id]
        )

        response = yield(event) if block_given?
      end

      response
    rescue CommandRetryableError => error
      if (tries -= 1).positive?
        retry
      else
        raise CommandError.new(code: 400, message: "Too many retries - #{error.message}")
      end
    end
  end

  def self.action(command_class)
    command_class.name.split("::")[-1]
  end
  private_class_method :action
end
