class AccessLimit < ApplicationRecord
  belongs_to :edition

  validate :user_uids_are_strings
  validate :user_organisations_are_uuids

  before_save :save_to_temp_columns

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

  def save_to_temp_columns
    self.temp_users = users
    self.temp_organisations = organisations
  end
end
