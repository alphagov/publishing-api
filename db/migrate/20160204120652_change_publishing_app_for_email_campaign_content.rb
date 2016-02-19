class ChangePublishingAppForEmailCampaignContent < ActiveRecord::Migration
  class DraftContentItem < ActiveRecord::Base; end
  class LiveContentItem < ActiveRecord::Base; end

  def change
    PathReservation.where(publishing_app: "email-campaign-frontend").each do |reservation|
      reservation.publishing_app = "share-sale-publisher"
      reservation.save(validate: false)
    end

    ContentItem.where(publishing_app: "email-campaign-frontend").each do |content_item|
      content_item.update_attributes!(publishing_app: "share-sale-publisher")

      state = State.find_by!(content_item: content_item)

      if state.name == "draft"
        content_store = Adapters::DraftContentStore
      elsif state.name == "published"
        content_store = Adapters::ContentStore
      end

      ContentStoreWorker.perform_async(
        content_store: content_store,
        content_item_id: content_item.id,
      ) if content_store
    end
  end
end
