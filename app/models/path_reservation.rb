class PathReservation < ApplicationRecord
  validates :base_path, absolute_path: true
  validates :publishing_app, presence: true

  validate :base_path_not_too_long

  def self.reserve_base_path!(base_path, publishing_app, override_existing: false)
    existing = find_by(base_path:)
    if existing.present? && override_existing
      existing.update!(publishing_app:)
    elsif existing.nil?
      create_path_reservation(base_path, publishing_app)
    else
      existing.ensure_unique(publishing_app)
    end
  rescue ActiveRecord::RecordInvalid => e
    raise e if e.is_a?(CustomRecordInvalid)

    raise map_to_custom_error(e.record)
  end

  def self.create_path_reservation(base_path, publishing_app)
    ActiveRecord::Base.transaction(requires_new: true) do
      create!(base_path:, publishing_app:)
    end
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
    # If a path is already reserved by the same publishing app, ignore the error
    find_by(base_path:).ensure_unique(publishing_app)
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
    CustomRecordInvalid.new(self, error_code: :base_path_already_reserved)
  end

  def base_path_not_too_long
    if base_path.bytesize > 512
      errors.add(:base_path, "over 512 bytes")
      CustomRecordInvalid.new(self, error_code: :base_path_too_long)
    end
  end

  def self.map_to_custom_error(record)
    if record.errors.added?(:publishing_app, :blank)
      CustomRecordInvalid.new(record, error_code: :publishing_app_missing)
    elsif record.errors.details[:base_path].any? { |e| e[:error] == "is not a valid absolute URL path" }
      CustomRecordInvalid.new(record, error_code: :base_path_invalid)
    else
      CustomRecordInvalid.new(record, error_code: :validation_failed)
    end
  end
end
