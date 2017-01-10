class Location < ApplicationRecord
  belongs_to :edition

  def self.filter(content_item_scope, base_path:)
    join_content_items(content_item_scope)
      .where("locations.base_path" => base_path)
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN locations ON locations.edition_id = editions.id"
    )
  end

private

  def base_path_present?
    base_path.present?
  end
end
