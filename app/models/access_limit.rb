class AccessLimit < ApplicationRecord
  belongs_to :edition

  validate :user_uids_are_strings
  validate :fact_check_ids_are_uuids

private

  def user_uids_are_strings
    unless users.all? { |id| id.is_a?(String) }
      errors.add(:users, ["contains non-string user UIDs"])
    end
  end

  def fact_check_ids_are_uuids
    unless fact_check_ids.all? { |id| UuidValidator.valid?(id) }
      errors.add(:fact_check_ids, ["contains invalid UUIDs"])
    end
  end
end
