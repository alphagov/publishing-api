class Command::Publish < Command::BaseCommand
  def call
    live_item = LiveContentItem.create_or_replace(draft_item.attributes.except("access_limited"))
    Adapters::ContentStore.new(services: services).call(live_item.base_path, live_payload(live_item))
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

  def live_payload(live_item)
    live_item.as_json.tap do |item|
      item["links"] = link_set.links if link_set.present?
    end
  end
end
