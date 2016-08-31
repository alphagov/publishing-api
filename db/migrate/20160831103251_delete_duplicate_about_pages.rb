class DeleteDuplicateAboutPages < ActiveRecord::Migration
  # Remove /government/organisations/animal-and-plant-health-agency/corporate_information_pages/623676
  def up
    content_id = "5ff02f7a-7631-11e4-a3cb-005056011aef"
    content_items = ContentItem.where(content_id: content_id)

    Helpers::DeleteContentItem.destroy_supporting_objects(content_items)

    content_items.destroy_all

    LinkSet.where(content_id: content_id).destroy_all
  end
end
