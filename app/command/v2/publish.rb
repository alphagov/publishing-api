class Command::V2::Publish < Command::BaseCommand
  attr_reader :live_item, :link_set

  def call
    validate!
    @live_item = LiveContentItem.create_or_replace(draft_item.attributes.except("access_limited")) do |live_item|
      raise CommandError.new(code: 400, message: "This item is already published") if live_item.version == draft_item.version
    end
    @link_set = LinkSet.find_by(content_id: content_id)

    Adapters::ContentStore.new.call(live_item.base_path, live_payload)

    send_to_message_queue!

    Command::Success.new(content_id: content_id)
  end

private
  def validate!
    raise CommandError.new(
      code: 422,
      message: "update_type is required",
      error_details: {
        error: {
          code: 422,
          message: "update_type is required",
          fields: {
            update_type: ["is required"],
          }
        }
      }
    ) unless update_type.present?
  end

  def content_id
    payload[:content_id]
  end

  def update_type
    payload[:update_type]
  end

  def draft_item
    DraftContentItem.find_by(content_id: content_id) or raise CommandError.new(code: 404, message: "Item with content_id #{content_id} does not exist")
  end

  def link_set_hash
    if link_set.present?
      {links: link_set.links.deep_symbolize_keys}
    else
      {}
    end
  end

  def live_payload
    Presenters::ContentItemPresenter.new(@live_item).present.merge(link_set_hash)
  end

  def send_to_message_queue!
    message_payload = live_payload.merge(update_type: update_type)
    PublishingAPI.service(:queue_publisher).send_message(message_payload)
  end

end
