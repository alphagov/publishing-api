class RemoveRedundantSpecialEducationNeedsPolicy < ActiveRecord::Migration
  # Remove government/policies/special-education-needs-sen
  def change
    content_items = ContentItem.where(content_id: "f656d065-43aa-4ab0-91f7-a6809ce5b68b")
    Translation.where(content_item: content_items).destroy_all
    Location.where(content_item: content_items).destroy_all
    State.where(content_item: content_items).destroy_all
    UserFacingVersion.where(content_item: content_items).destroy_all
    AccessLimit.where(content_item: content_items).destroy_all
    LockVersion.where(target: content_items).destroy_all
    content_items.destroy_all

    link_sets = LinkSet.where(content_id: "f656d065-43aa-4ab0-91f7-a6809ce5b68b")
    link_sets.destroy_all
  end
end
