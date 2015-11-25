class Version < ActiveRecord::Base
  belongs_to :target, polymorphic: true

  validate :numbers_must_increase
  validate :draft_cannot_be_behind_live

  def increment
    self.number += 1
  end

  def copy_version_from(target)
    version = Version.find_by!(target: target)
    self.number = version.number
  end

  def conflicts_with?(previous_version_number)
    return false if previous_version_number.nil?

    self.number != previous_version_number
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
    live_version = live_content_item_version
    return unless live_version

    if number < live_version.number
      mismatch = "(#{number} < #{live_version.number})"
      message = "draft version cannot be behind the live version #{mismatch}"
      errors.add(:version, message)
    end
  end

  def live_content_item_version
    return unless target.respond_to?(:live_content_item)
    return unless (live_item = target.live_content_item)

    self.class.find_by(target: live_item)
  end

  def draft_content_item_version
    return unless target.respond_to?(:draft_content_item)
    return unless (draft_item = target.draft_content_item)

    self.class.find_by(target: draft_item)
  end
end
