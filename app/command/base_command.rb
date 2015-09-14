class Command::BaseCommand
  attr_reader :event, :services

  def initialize(event, services = PublishingAPI)
    @event = event
    @services = services
  end

  def payload
    event.payload
  end

  def base_path
    payload['base_path']
  end

private
  def draft_content_store
    services.service(:draft_content_store)
  end

  def live_content_store
    services.service(:live_content_store)
  end

  def queue_publisher
    services.service(:queue_publisher)
  end

  def url_arbiter
    services.service(:url_arbiter)
  end
end
