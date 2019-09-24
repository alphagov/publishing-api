class User < ApplicationRecord
  include GDS::SSO::User

  serialize :permissions, Array

  def set_app_name!
    if app_name.blank? && email.present?
      self.app_name = email.split("@")[0]
      save!
    end
  end
end
