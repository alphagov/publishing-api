class State < ApplicationRecord
  belongs_to :edition, foreign_key: "content_item_id"

  def self.filter(content_item_scope, name:)
    join_content_items(content_item_scope)
      .where("states.name" => name)
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN states ON states.content_item_id = content_items.id"
    )
  end
end
