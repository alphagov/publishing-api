class PathReservation < ActiveRecord::Base
  include Replaceable

  validates :base_path, :absolute_path => true
  validates :publishing_app, :presence => true
  validates_with PublishingAppValidator

  def self.reserve_base_path!(base_path, publishing_app)
    self.create_or_replace(base_path: base_path, publishing_app: publishing_app)
  end

  def self.query_keys
    [:base_path]
  end
end
