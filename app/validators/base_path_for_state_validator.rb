class BasePathForStateValidator < ActiveModel::Validator
  def validate(record)
    return unless record.state && record.base_path

    check_conflict(record)
  end

private

  def check_conflict(record)
    conflict = Queries::BasePathForState.conflict(record.id, record.state, record.base_path)
    if conflict
      record.errors.add(:base, error_message(record.base_path, conflict))
    end
  end

  def error_message(base_path, conflict)
    message = "base path=#{base_path} conflicts with content_id=#{conflict[:content_id]}"
    message << " and locale=#{conflict[:locale]}" if conflict[:locale]
    message
  end
end
