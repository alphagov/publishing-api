class ReassociateContentItems < ActiveRecord::Migration
  def change
    # This migration fixes a problem introduced in this migration:
    # AddDraftContentItemIdToLiveContentItem
    #
    # The DraftContentItem.find_by call should have scoped by locale.
    #
    # This migration re-assocates all incorrectly associated live content
    # items with the draft item that matches the locale.

    mismatches = LiveContentItem.all.select do |live_item|
      draft_item = live_item.draft_content_item
      live_item.locale != draft_item.locale
    end

    mismatches.each do |live_item|
      draft_item = DraftContentItem.find_by!(
        content_id: live_item.content_id,
        locale: live_item.locale
      )

      live_item.update!(draft_content_item: draft_item)
    end
  end
end
