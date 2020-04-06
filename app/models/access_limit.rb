class AccessLimit < ApplicationRecord
  belongs_to :edition

  validate :user_uids_are_strings
  validate :user_organisations_are_uuids

private

  def user_uids_are_strings
    unless users.all? { |id| id.is_a?(String) }
      errors.add(:users, ["contains non-string user UIDs"])
    end
  end

  def user_organisations_are_uuids
    unless organisations.all? { |id| UuidValidator.valid?(id) }
      errors.add(:organisations, ["contains invalid UUIDs"])
    end
  end
end
