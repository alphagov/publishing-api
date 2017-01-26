class State < ApplicationRecord
  belongs_to :edition, foreign_key: "content_item_id"

  def self.filter(edition_scope, name:)
    join_editions(edition_scope).where("states.name" => name)
  end

  def self.join_editions(edition_scope)
    edition_scope.joins("INNER JOIN states ON states.content_item_id = content_items.id")
  end
end
