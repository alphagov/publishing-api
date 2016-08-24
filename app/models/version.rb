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

  def draft_and_live_versions
    result = Queries::DraftAndLiveVersions.call(target, self.class.name.tableize)
    if result["draft"] == self.number
      draft_version = self.number
      live_version = result["published"]
    elsif result["published"] == self.number
      draft_version = result["draft"]
      live_version = self.number
    end

    [draft_version, live_version]
  end

  def draft_cannot_be_behind_live
    draft_version, live_version = draft_and_live_versions

    return unless draft_version && live_version

    if draft_version < live_version
      mismatch = "(#{draft_version} < #{live_version})"
      message = "draft #{self.class.name} cannot be behind the live #{self.class.name} #{mismatch}"
      errors.add(:number, message)
    end
  end
end
