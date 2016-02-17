class ChangePublishingAppForEmailCampaignContent < ActiveRecord::Migration
  def change
    PathReservation.where(publishing_app: "email-campaign-frontend").each do |reservation|
      reservation.publishing_app = "share-sale-publisher"
      reservation.save(validate: false)
    end

    DraftContentItem.where(publishing_app: "email-campaign-frontend").each do |content_item|
      content_item.update_attributes!(publishing_app: "share-sale-publisher")

      ContentStoreWorker.perform_async(
        content_store: Adapters::DraftContentStore,
        draft_content_item_id: content_item.id,
      )
    end

    LiveContentItem.where(publishing_app: "email-campaign-frontend").each do |content_item|
      content_item.update_attributes!(publishing_app: "share-sale-publisher")

      ContentStoreWorker.perform_async(
        content_store: Adapters::ContentStore,
        live_content_item_id: content_item.id,
      )
    end
  end
end
