class Location < ApplicationRecord
  belongs_to :edition, foreign_key: "content_item_id"

  def self.filter(edition_scope, base_path:)
    join_editions(edition_scope).where("locations.base_path" => base_path)
  end

  def self.join_editions(edition_scope)
    edition_scope.joins("INNER JOIN locations ON locations.content_item_id = content_items.id")
  end

private

  def base_path_present?
    base_path.present?
  end
end
