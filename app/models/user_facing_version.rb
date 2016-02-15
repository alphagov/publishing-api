class UserFacingVersion < ActiveRecord::Base
  belongs_to :content_item

  validate :numbers_must_increase

  validates_with ContentItemUniquenessValidator
  validate :draft_cannot_be_behind_live

  def self.filter(content_item_scope, number:)
    content_item_scope
      .joins("INNER JOIN user_facing_versions ON user_facing_versions.content_item_id = content_items.id")
      .where("user_facing_versions.number" => number)
  end

  def self.latest(content_item_scope)
    content_item_scope
      .joins("INNER JOIN user_facing_versions ON user_facing_versions.content_item_id = content_items.id")
      .order("user_facing_versions.number asc")
      .last
  end

  def increment
    self.number += 1
  end

private

  def numbers_must_increase
    return unless persisted?
    return unless number <= number_was

    mismatch = "(#{number} <= #{number_was})"
    message = "cannot be less than or equal to the previous number #{mismatch}"
    errors.add(:number, message)
  end

  def draft_cannot_be_behind_live
    draft = ContentItemFilter.similar_to(content_item, state: "draft", user_ver: nil).first
    live = ContentItemFilter.similar_to(content_item, state: "published", user_ver: nil).first

    if draft == content_item
      draft_version = self
      live_version = self.class.find_by(content_item: live)
    elsif live == content_item
      draft_version = self.class.find_by(content_item: draft)
      live_version = self
    end

    return unless draft_version && live_version

    if draft_version.number < live_version.number
      mismatch = "(#{draft_version.number} < #{live_version.number})"
      message = "draft version cannot be behind the live version #{mismatch}"
      errors.add(:number, message)
    end
  end
end
