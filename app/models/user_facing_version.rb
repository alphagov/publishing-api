class UserFacingVersion < ApplicationRecord
  include Version

  belongs_to :content_item

  after_save do
    content_item.update_attributes!(user_facing_version: number)
  end

  def self.filter(content_item_scope, number:)
    join_content_items(content_item_scope)
      .where("user_facing_versions.number" => number)
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN user_facing_versions ON user_facing_versions.content_item_id = content_items.id"
    )
  end

private

  def content_item_target?
    true
  end

  def target
    content_item
  end
end
