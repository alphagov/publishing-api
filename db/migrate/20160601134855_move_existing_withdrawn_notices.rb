class MoveExistingWithdrawnNotices < ActiveRecord::Migration
  def change
    Unpublishing.where(type: "withdrawal").find_each do |unpublishing|
      content_item = unpublishing.content_item
      event = Event.create!(
        action: "Unpublish",
        content_id: content_item.content_id,
        payload: {
          content_id: content_item.content_id,
          type: "withdrawal",
          publishing_app: content_item.publishing_app
        },
      )

      PresentedContentStoreWorker.perform_async(
        content_store: Adapters::ContentStore,
        payload: { content_item_id: unpublishing.content_item_id, payload_version: event.id },
        request_uuid: GdsApi::GovukHeaders.headers[:govuk_request_id],
      )
    end
  end
end
