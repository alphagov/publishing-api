class PathReservation < ActiveRecord::Base
  validates :base_path, absolute_path: true
  validates :publishing_app, presence: true
  validates_with PublishingAppValidator

  def self.reserve_base_path!(base_path, publishing_app)
    record = find_or_initialize_by(base_path: base_path)
    record.publishing_app = publishing_app
    record.save!
  end
end
