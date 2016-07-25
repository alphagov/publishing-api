class ContentItemUniquenessValidator < ActiveModel::Validator
  def validate(record)
    return unless record.content_item

    content_item = record.content_item
    unique_fields = Queries::ContentItemUniqueness.unique_fields_for_content_item(content_item)

    return unless unique_fields

    base_path = record.is_a?(Location) ? record.base_path : unique_fields[:base_path]
    locale = record.is_a?(Translation) ? record.locale : unique_fields[:locale]
    state = record.is_a?(State) ? record.name : unique_fields[:state]
    user_facing_version = record.is_a?(UserFacingVersion) ? record.number : unique_fields[:user_facing_version]

    required_fields = [state, locale, user_facing_version]
    required_fields << base_path if content_item.requires_base_path?

    return unless required_fields.all?

    # We should only have one content item at a given path (and locale) for each
    # content store. Superseded content items aren't in either content store so
    # we can relax this validation.
    return if state == "superseded"

    non_unique = Queries::ContentItemUniqueness.first_non_unique_item(
      content_item,
      base_path: base_path,
      locale: locale,
      state: state,
      user_facing_version: user_facing_version,
    )

    if non_unique
      error = "conflicts with a duplicate: "
      error << "state=#{state}, "
      error << "locale=#{locale}, "
      error << "base_path=#{base_path}, "
      error << "user_version=#{user_facing_version}, "
      error << "content_id=#{non_unique[:content_id]}"

      record.errors.add(:content_item, error)
    end
  end
end
