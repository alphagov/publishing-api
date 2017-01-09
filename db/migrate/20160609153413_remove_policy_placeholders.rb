class RemovePolicyPlaceholders < ActiveRecord::Migration
  def change
    ContentItem.transaction do
      results = ContentItem.where(content_id: content_ids_to_delete).pluck(:id, :content_id)
      ids = results.map { |r| r[0] }
      content_ids = results.map { |r| r[1] }

      State.where(content_item_id: ids).delete_all
      Location.where(content_item_id: ids).delete_all
      Translation.where(content_item_id: ids).delete_all
      UserFacingVersion.where(content_item_id: ids).delete_all
      ContentItem.where(id: ids).delete_all

      Link.joins(:link_set).where(link_sets: {content_id: content_ids}).delete_all
      LinkSet.where(content_id: content_ids).delete_all
    end
  end

  def content_ids_to_delete
    %w(12a4eb7a-6037-4cc0-aa58-0a4f2fbc5e7f e0deb0ec-e9fc-4308-b8c0-eba4dc92aa83 f656d065-43aa-4ab0-91f7-a6809ce5b68b)
  end
end
