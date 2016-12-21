class VersionForLocaleValidator < ActiveModel::Validator
  def validate(record)
    return unless record.locale && record.user_facing_version

    criteria = {
      document: record.document,
      user_facing_version: record.user_facing_version,
    }

    conflict = ContentItem.where(criteria).where.not(id: record.id).first

    if conflict
      error = "user_facing_version=#{record.user_facing_version} and "
      error << "locale=#{record.locale} for content item=#{record.content_id} "
      error << "conflicts with content item id=#{conflict[:id]}"
      record.errors.add(:base, error)
    end
  end
end
