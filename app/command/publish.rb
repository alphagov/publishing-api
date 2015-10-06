class Command::Publish < Command::BaseCommand
  attr_reader :live_item

  def call
    @live_item = LiveContentItem.create_or_replace(draft_item.attributes.except("access_limited"))

    Adapters::ContentStore.new(services: services).call(live_item.base_path, live_payload)
    queue_publisher.send_message(live_payload)

    Command::Success.new(content_id: content_id)
  end

private
  def content_id
    payload["content_id"]
  end

  def draft_item
    DraftContentItem.find_by(content_id: content_id)
  end

  def link_set
    @link_set ||= LinkSet.find_by(content_id: content_id)
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
end
