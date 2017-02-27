require_relative "helpers/delete_content"
class ClearSomeContentToAllowWhitehallRepublishing < ActiveRecord::Migration[5.0]
  def up
    content_ids = [
      #/government/statistics/how-he-statistics-are-used
      "5c848d93-7631-11e4-a3cb-005056011aef",
      #/government/publications/mod-desg-graduate-trainee
      "5c9034ed-7631-11e4-a3cb-005056011aef",
    ]

    Helpers::DeleteContent.destroy_documents_with_links(content_ids)
  end
end
