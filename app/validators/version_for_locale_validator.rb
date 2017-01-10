class VersionForLocaleValidator < ActiveModel::Validator
  def validate(record)
    return unless record.document && record.user_facing_version

    criteria = {
      document: record.document,
      user_facing_version: record.user_facing_version,
    }

    conflict = Edition.where(criteria).where.not(id: record.id).order(nil).first

    if conflict
      error = "user_facing_version=#{record.user_facing_version} and "
      error << "locale=#{record.locale} for content item=#{record.content_id} "
      error << "conflicts with content item id=#{conflict[:id]}"
      record.errors.add(:base, error)
    end
  end
end
