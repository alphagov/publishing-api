class UserFacingVersion < ActiveRecord::Base
  belongs_to :content_item

  validate :numbers_must_increase

  validates_with ContentItemUniquenessValidator
  # validate :draft_cannot_be_behind_live

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

  # def copy_version_from(target)
  #   version = Version.find_by!(target: target)
  #   self.number = version.number
  # end
  #
  # def conflicts_with?(previous_version_number)
  #   return false if previous_version_number.nil?
  #
  #   self.number != previous_version_number
  # end
  #
  # def self.in_bulk(items, type)
  #   id_list = items.reject(&:blank?).map(&:id)
  #   self.where(target: id_list, target_type: type.to_s).index_by(&:target_id)
  # end

private

  def numbers_must_increase
    return unless persisted?
    return unless number <= number_was

    mismatch = "(#{number} <= #{number_was})"
    message = "cannot be less than or equal to the previous number #{mismatch}"
    errors.add(:number, message)
  end

  # def draft_cannot_be_behind_live
  #   return unless target.is_a?(ContentItem)
  #
  #   live_version = live_content_item_version
  #   return unless live_version
  #
  #   if number < live_version.number
  #     mismatch = "(#{number} < #{live_version.number})"
  #     message = "draft version cannot be behind the live version #{mismatch}"
  #     errors.add(:version, message)
  #   end
  # end
  #
  # def live_content_item_version
  #   live_content_item = ContentItemFilter.similar_to(target, state: "published").first
  #   self.class.find_by(target: live_content_item)
  # end
  #
  # def draft_content_item_version
  #   draft_content_item = ContentItemFilter.similar_to(target, state: "draft").first
  #   self.class.find_by(target: draft_content_item)
  # end
end
