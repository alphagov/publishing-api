class AccessLimit < ApplicationRecord
  belongs_to :edition

  validate :user_uids_are_strings
  validate :auth_bypass_ids_are_uuids

private

  def user_uids_are_strings
    unless users.all? { |id| id.is_a?(String) }
      errors.add(:users, ["contains non-string user UIDs"])
    end
  end

  def auth_bypass_ids_are_uuids
    unless auth_bypass_ids.all? { |id| UuidValidator.valid?(id) }
      errors.add(:auth_bypass_ids, ["contains invalid UUIDs"])
    end
  end
end
