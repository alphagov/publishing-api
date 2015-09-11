class CommandProcessor
  attr_reader :base_path, :user_id, :item

  def initialize(base_path, user_id, item)
    @base_path = base_path
    @user_id = user_id
    @item = item
  end

  def put_content_with_links
    event = log_event('PutContentWithLinks')
    Command::PutContentWithLinks.new(event).call
  end

  def put_draft_content_with_links
    event = log_event('PutDraftContentWithLinks')
    Command::PutDraftContentWithLinks.new(event).call
  end

  private

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
