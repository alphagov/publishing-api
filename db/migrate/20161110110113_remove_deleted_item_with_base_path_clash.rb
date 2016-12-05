require_relative "helpers/delete_content_item"

class RemoveDeletedItemWithBasePathClash < ActiveRecord::Migration[5.0]
  def change
    Helpers::DeleteContentItem.destroy_content_items_with_links("7f25968a-4705-428b-9f34-93001bb0c475")
  end
end
