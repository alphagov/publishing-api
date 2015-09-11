class Query::GetPublishIntent
  attr_reader :base_path

  def initialize(base_path)
    @base_path = base_path
  end

  def call
    live_content_store.get_publish_intent(base_path)
  end

private

  def live_content_store
    PublishingAPI.services(:live_content_store)
  end
end
