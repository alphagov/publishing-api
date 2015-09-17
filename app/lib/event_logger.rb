class EventLogger
  def log(action, user_id, payload, &block)
    Event.connection.transaction do
      event = Event.create(action: action, user_uid: user_id, payload: payload)
      if block_given?
        yield(event)
      end
    end
  end
end
