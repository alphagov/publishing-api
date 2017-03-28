require_relative "helpers/delete_content"

class RemoveLandRegistry < ActiveRecord::Migration[5.0]
  def up
    land_registry_content_ids = [
      "4ac6acfd-2ff4-427b-b952-eca13bb14d88",
      "5fe3c59c-7631-11e4-a3cb-005056011aef",
    ]

    Helpers::DeleteContent.destroy_documents_with_links(land_registry_content_ids)
  end
end
