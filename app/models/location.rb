class Location < ApplicationRecord
  belongs_to :edition, foreign_key: "content_item_id"

  def self.filter(content_item_scope, base_path:)
    join_content_items(content_item_scope)
      .where("locations.base_path" => base_path)
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN locations ON locations.content_item_id = content_items.id"
    )
  end

private

  def base_path_present?
    base_path.present?
  end
end
