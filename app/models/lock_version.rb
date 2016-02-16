class LockVersion < ActiveRecord::Base
  belongs_to :target, polymorphic: true

  validate :numbers_must_increase

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN lock_versions ON
        lock_versions.target_id = content_items.id AND
        lock_versions.target_type = 'ContentItem'"
    )
  end

  def increment
    self.number += 1
  end

  def copy_version_from(target)
    lock_version = LockVersion.find_by!(target: target)
    self.number = lock_version.number
  end

  def conflicts_with?(previous_version_number)
    return false if previous_version_number.nil?

    self.number != previous_version_number.to_i
  end

  def self.in_bulk(items, type)
    id_list = items.reject(&:blank?).map(&:id)
    self.where(target: id_list, target_type: type.to_s).index_by(&:target_id)
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
    return unless target.is_a?(ContentItem)

    live_version = live_content_item_version
    return unless live_version

    if number < live_version.number
      mismatch = "(#{number} < #{live_version.number})"
      message = "draft lock_version cannot be behind the live lock_version #{mismatch}"
      errors.add(:lock_version, message)
    end
  end

  def live_content_item_version
    live_content_item = ContentItemFilter.similar_to(target, state: "published").first
    self.class.find_by(target: live_content_item)
  end

  def draft_content_item_version
    draft_content_item = ContentItemFilter.similar_to(target, state: "draft").first
    self.class.find_by(target: draft_content_item)
  end
end
