class UrlReservation < ActiveRecord::Base
  validates :path, :uniqueness => true, :absolute_path => true
  validates :publishing_app, :presence => true
  validates_with PublishingAppValidator

  def self.reserve_path!(path, publishing_app)
    self.find_or_initialize_by(path: path).update_attributes!(publishing_app: publishing_app)
  end
end
