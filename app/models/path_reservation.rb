class PathReservation < ActiveRecord::Base
  validates :base_path, :uniqueness => true, :absolute_path => true
  validates :publishing_app, :presence => true
  validates_with PublishingAppValidator

  def self.reserve_base_path!(base_path, publishing_app)
    self.find_or_initialize_by(base_path: base_path).update_attributes!(publishing_app: publishing_app)
  end
end
