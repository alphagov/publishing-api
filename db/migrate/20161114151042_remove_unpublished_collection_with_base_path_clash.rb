require_relative "helpers/delete_content_item"

class RemoveUnpublishedCollectionWithBasePathClash < ActiveRecord::Migration[5.0]
  def change
    Helpers::DeleteContentItem.destroy_content_items_with_links("5eb78f34-7631-11e4-a3cb-005056011aef")
  end
end
