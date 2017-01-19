class UserFacingVersion < ApplicationRecord
  belongs_to :edition, foreign_key: "content_item_id"

  def self.filter(edition_scope, number:)
    join_content_items(edition_scope)
      .where("user_facing_versions.number" => number)
  end

  def self.join_content_items(edition_scope)
    edition_scope.joins(
      "INNER JOIN user_facing_versions ON user_facing_versions.content_item_id = content_items.id"
    )
  end

private

  def edition_target?
    true
  end

  def target
    edition
  end
end
