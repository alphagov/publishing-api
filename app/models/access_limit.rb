class AccessLimit < ApplicationRecord
  belongs_to :edition

  after_save :copy_auth_bypass_ids_to_edition

  validate :user_uids_are_strings
  validate :auth_bypass_ids_are_uuids
  validate :user_organisations_are_uuids

private

  def copy_auth_bypass_ids_to_edition
    edition.update!(auth_bypass_ids: auth_bypass_ids)
  end

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

  def user_organisations_are_uuids
    unless organisations.all? { |id| UuidValidator.valid?(id) }
      errors.add(:organisations, ["contains invalid UUIDs"])
    end
  end
end
