class PublishIntentsController < ApplicationController
  include URLArbitration

  def create_or_update
    with_url_arbitration do
      live_content_store.put_publish_intent(
        base_path: base_path,
        publish_intent: content_item
      )

      render json: content_item
    end
  end

private

  def live_content_store
    PublishingAPI.services(:live_content_store)
  end
end
