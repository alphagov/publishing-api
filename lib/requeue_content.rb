class RequeueContent
  def initialize(number_of_items: nil)
    @number_of_items = number_of_items
  end

  attr_accessor :number_of_items

  def call
    if number_of_items.present?
      ContentItem.where(state: :published).limit(number_of_items).each do |content_item|
        publish_to_queue(content_item)
      end
    else
      ContentItem.where(state: :published).find_each do |content_item|
        publish_to_queue(content_item)
      end
    end
  end

private

  def publish_to_queue(content_item)
    downstream_presenter = Presenters::DownstreamPresenter.new(
      Queries::GetWebContentItems.find(content_item.id),
      state_fallback_order: [:published]
    )
    queue_payload = Presenters::MessageQueuePresenter.present(
      downstream_presenter,
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
