class EventLogger
  def log(action, user_id, payload, &block)
    tries = 3
    begin
      Event.connection.transaction do
        event = Event.create(action: action, user_uid: user_id, payload: payload)
        if block_given?
          yield(event)
        end
      end
    rescue CommandRetryError => e
      if (tries -= 1) > 0
        retry
      else
        raise CommandError.new(code: 500, message: "Too many retries - #{e.message}")
      end
    end
  end
end
