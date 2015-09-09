class EventLogger
  def log(action, user_id, payload)
    Event.create(action: action, user_uid: user_id, payload: payload)
  end
end
