class RequeueContent
  def initialize(number_of_items: nil)
    @number_of_items = number_of_items
  end

  attr_accessor :number_of_items

  def call
    if number_of_items.present?
      ContentItemFilter.filter(state: :published).limit(number_of_items).each do |content_item|
        publish_to_queue(content_item)
      end
    else
      ContentItemFilter.filter(state: :published).find_each do |content_item|
        publish_to_queue(content_item)
      end
    end
  end

private

  def publish_to_queue(content_item)
    queue_payload = Presenters::MessageQueuePresenter.present(
      content_item,
      fallback_order: [:published],
      # FIXME: Rummager currently only listens to the message queue for the
      # update type 'links'. This behaviour will eventually be updated so that
      # it listens to other update types as well. This will happen as part of
      # ongoing architectural work to make the message queue the sole source of
      # search index updates. When that happens, the update_type below should
      # be changed - perhaps to a newly introduced, more-appropriately named
      # one. Maybe something like 'reindex'.
      update_type: 'links'
    )

    PublishingAPI.service(:queue_publisher).send_message(queue_payload)
  end
end
