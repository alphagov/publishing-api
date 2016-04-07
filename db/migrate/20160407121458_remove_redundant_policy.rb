class RemoveRedundantPolicy < ActiveRecord::Migration
  # Remove /government/policies/schools-and-college-qualifications-and-curriculum
  def up
    content_items = ContentItem.where(content_id: "3c04de88-9e4a-4ebb-bdc9-ef5946db17b9")
    Translation.where(content_item: content_items).destroy_all
    Location.where(content_item: content_items).destroy_all
    State.where(content_item: content_items).destroy_all
    UserFacingVersion.where(content_item: content_items).destroy_all
    AccessLimit.where(content_item: content_items).destroy_all
    LockVersion.where(target: content_items).destroy_all
    content_items.destroy_all

    link_sets = LinkSet.where(content_id: "3c04de88-9e4a-4ebb-bdc9-ef5946db17b9")
    link_sets.destroy_all
  end
end
