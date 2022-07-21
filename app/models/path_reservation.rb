class PathReservation < ApplicationRecord
  validates :base_path, absolute_path: true
  validates :publishing_app, presence: true

  def self.reserve_base_path!(base_path, publishing_app, override_existing: false)
    existing = find_by(base_path: base_path)
    if existing.present? && override_existing
      existing.update!(publishing_app: publishing_app)
    elsif existing.nil?
      create_path_reservation(base_path, publishing_app)
    else
      existing.ensure_unique(publishing_app)
    end
  end

  def self.create_path_reservation(base_path, publishing_app)
    ActiveRecord::Base.transaction(requires_new: true) do
      create!(base_path: base_path, publishing_app: publishing_app)
    end
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
    # If a path is already reserved by the same publishing app, ignore the error
    find_by(base_path: base_path).ensure_unique(publishing_app)
  end

  def ensure_unique(publishing_app)
    if already_associated_with?(publishing_app)
      self
    else
      raise already_reserved_error
    end
  end

  def already_associated_with?(publishing_app)
    publishing_app == self.publishing_app
  end

  def already_reserved_error
    msg = "#{base_path} is already reserved by #{publishing_app}"
    errors.add(:base_path, msg)
    ActiveRecord::RecordInvalid.new(self)
  end
end
