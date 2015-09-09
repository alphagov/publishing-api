class PublishIntentsController < ApplicationController
  include URLArbitration

  before_filter :parse_content_item, only: [:create_or_update]

  def create_or_update
    with_url_arbitration do
      EventLogger.new.log('PutPublishIntent', nil, content_item.merge("base_path" => base_path))

      live_content_store.put_publish_intent(
        base_path: base_path,
        publish_intent: content_item
      )

      render json: content_item
    end
  end

  def show
    render json: live_content_store.get_publish_intent(base_path)
  end

  def destroy
    EventLogger.new.log('DeletePublishIntent', nil, {"base_path" => base_path})

    live_content_store.delete_publish_intent(base_path)
    render json: {}
  end

private

  def live_content_store
    PublishingAPI.services(:live_content_store)
  end
end
