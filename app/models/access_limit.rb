class AccessLimit < ActiveRecord::Base
  belongs_to :target, polymorphic: true

  validate :user_uids_are_strings

  def self.viewable?(target, user_uid: nil)
    if (access_limit = self.find_by(target: target))
      user_uid.present? && access_limit.users.include?(user_uid)
    else
      true
    end
  end

private

  def user_uids_are_strings
    unless users.all? { |id| id.is_a?(String) }
      errors.set(:users, ["contains non-string user UIDs"])
    end
  end
end
