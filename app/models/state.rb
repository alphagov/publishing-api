class State < ApplicationRecord
  belongs_to :edition

  def self.filter(content_item_scope, name:)
    join_content_items(content_item_scope)
      .where("states.name" => name)
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN states ON states.edition_id = editions.id"
    )
  end
end
