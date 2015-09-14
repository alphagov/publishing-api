class CommandProcessor
  attr_reader :base_path, :user_id, :item

  def initialize(base_path, user_id, item)
    @base_path = base_path
    @user_id = user_id
    @item = item
  end

  def put_content_with_links
    dispatch(Command::PutContentWithLinks)
  end

  def put_draft_content_with_links
    dispatch(Command::PutDraftContentWithLinks)
  end

  def put_publish_intent
    dispatch(Command::PutPublishIntent)
  end

  def delete_publish_intent
    dispatch(Command::DeletePublishIntent)
  end

private
  def dispatch(command_class)
    event = log_event(command_name(command_class))
    command_class.new(event).call
  end

  def command_name(command_class)
    command_class.name.split("::")[-1]
  end

  def item_with_base_path
    @item.merge(base_path: base_path)
  end

  def log_event(command_name)
    event_logger.log(command_name, user_id, item_with_base_path)
  end

  def event_logger
    EventLogger.new
  end
end
