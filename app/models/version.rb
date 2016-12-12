# Abstract class
module Version
  def self.included(subclass)
    subclass.validate :numbers_must_increase
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
end
