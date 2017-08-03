class RequeueContent
  def initialize(number_of_items: nil)
    @number_of_items = number_of_items
  end

  attr_accessor :number_of_items

  def call
    if number_of_items.present?
      Edition.where(state: :published).limit(number_of_items).each do |edition|
        publish_to_queue(edition)
      end
    else
      Edition.where(state: :published).find_each do |edition|
        publish_to_queue(edition)
      end
    end
  end

private

  def publish_to_queue(edition)
    version = Event.maximum(:id)

    queue_payload = Presenters::EditionPresenter.new(
      edition, draft: false,
    ).for_message_queue(version)

    # FIXME: Rummager currently only listens to the message queue for the
    # event type 'links'. This behaviour will eventually be updated so that
    # it listens to other update types as well. This will happen as part of
    # ongoing architectural work to make the message queue the sole source of
    # search index updates. When that happens, the event_type below should
    # be changed - perhaps to a newly introduced, more-appropriately named
    # one. Maybe something like 'reindex'.

    PublishingAPI.service(:queue_publisher).send_message(queue_payload, event_type: "links")
  end
end
