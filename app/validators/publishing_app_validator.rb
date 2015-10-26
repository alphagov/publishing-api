class PublishingAppValidator < ActiveModel::Validator
  def validate(record)
    if record.persisted? && record.publishing_app_changed?
      record.errors.add(:base_path, "is already registered by #{record.publishing_app_was}")
    end
  end
end
