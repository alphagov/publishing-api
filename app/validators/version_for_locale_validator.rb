class VersionForLocaleValidator < ActiveModel::Validator
  def validate(record)
    return unless record.content_item

    content_item = record.content_item
    locale = content_item_locale(record)
    user_facing_version = content_item_user_facing_version(record)

    return unless locale && user_facing_version

    conflict = Queries::VersionForLocale.conflict(
      content_item.id,
      content_item.content_id,
      locale,
      user_facing_version
    )

    if conflict
      error = "user_facing_version=#{user_facing_version} and locale=#{locale} "
      error << "for content item=#{content_item.content_id} conflicts with "
      error << "content item id=#{conflict[:id]}"
      record.errors.add(:content_item, error)
    end
  end

private

  def content_item_locale(record)
    return record.locale if record.is_a?(Translation)
    Translation.where(content_item: record.content_item).pluck(:locale).first
  end

  def content_item_user_facing_version(record)
    return record.number if record.is_a?(UserFacingVersion)
    UserFacingVersion.where(content_item: record.content_item).pluck(:number).first
  end
end
