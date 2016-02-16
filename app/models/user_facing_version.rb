class UserFacingVersion < ActiveRecord::Base
  include Version

  belongs_to :content_item

  validates_with ContentItemUniquenessValidator

  def self.filter(content_item_scope, number:)
    join_content_items(content_item_scope)
      .where("user_facing_versions.number" => number)
  end

  def self.latest(content_item_scope)
    join_content_items(content_item_scope)
      .order("user_facing_versions.number asc")
      .last
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

  def draft_and_live_versions
    draft = ContentItemFilter.similar_to(content_item, state: "draft", user_version: nil).first
    live = ContentItemFilter.similar_to(content_item, state: "published", user_version: nil).first

    if draft == content_item
      draft_version = self
      live_version = self.class.find_by(content_item: live)
    elsif live == content_item
      draft_version = self.class.find_by(content_item: draft)
      live_version = self
    end

    [draft_version, live_version]
  end
end
