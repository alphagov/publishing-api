# Abstract class
module Version
  def self.included(subclass)
    subclass.validate :numbers_must_increase
    subclass.validate :draft_cannot_be_behind_live, if: :content_item_target?
  end

  def increment
    self.number += 1
  end

private

  def numbers_must_increase
    return unless persisted?
    return unless number_changed? && number <= number_was

    mismatch = "(#{number} <= #{number_was})"
    message = "cannot be less than or equal to the previous number #{mismatch}"
    errors.add(:number, message)
  end

  def draft_cannot_be_behind_live
    draft_version, live_version = draft_and_live_versions

    return unless draft_version && live_version

    if draft_version.number < live_version.number
      mismatch = "(#{draft_version.number} < #{live_version.number})"
      message = "draft #{self.class.name} cannot be behind the live #{self.class.name} #{mismatch}"
      errors.add(:number, message)
    end
  end
end
