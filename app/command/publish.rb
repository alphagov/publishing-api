class Command::Publish < Command::BaseCommand
  attr_reader :live_item, :link_set

  def call
    @live_item = LiveContentItem.create_or_replace(draft_item.attributes.except("access_limited"))
    @link_set = LinkSet.find_by(content_id: content_id)

    Adapters::ContentStore.new(services: services).call(live_item.base_path, live_payload)

    send_to_message_queue!

    Command::Success.new(content_id: content_id)
  end

private
  def content_id
    payload["content_id"]
  end

  def draft_item
    DraftContentItem.find_by(content_id: content_id) or raise Command::Error.new(code: 404, message: "Item with content_id #{content_id} does not exist")
  end

  def link_set_hash
    if link_set.present?
      {"links" => link_set.links}
    else
      {}
    end
  end

  def live_payload
    Presenters::ContentItemPresenter.new(@live_item).present.merge(link_set_hash)
  end

  def send_to_message_queue!
    message_payload = live_payload.merge(update_type: payload['update_type'])
    queue_publisher.send_message(message_payload)
  end

end
