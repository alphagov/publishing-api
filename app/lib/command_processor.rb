class CommandProcessor
  attr_reader :user_id, :event_logger

  def initialize(user_id, event_logger: EventLogger.new)
    @user_id = user_id
    @event_logger = event_logger
  end

  def put_content(payload)
    dispatch(Command::V2::PutContent, payload)
  end

  def put_content_with_links(payload)
    dispatch(Command::PutContentWithLinks, payload)
  end

  def put_draft_content_with_links(payload)
    dispatch(Command::PutDraftContentWithLinks, payload)
  end

  def put_publish_intent(payload)
    dispatch(Command::PutPublishIntent, payload)
  end

  def delete_publish_intent(payload)
    dispatch(Command::DeletePublishIntent, payload)
  end

private
  def dispatch(command_class, payload)
    event_logger.log(command_name(command_class), user_id, payload) do |event|
      command_class.new(event).call
    end
  end

  def command_name(command_class)
    command_class.name.split("::")[-1]
  end

  def item_with_base_path
    @item.merge(base_path: base_path)
  end
end
