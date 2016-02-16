class ContentItemUniquenessValidator < ActiveModel::Validator
  def validate(record)
    content_item = record.content_item

    state = record if record.is_a?(State)
    translation = record if record.is_a?(Translation)
    location = record if record.is_a?(Location)
    user_facing_version = record if record.is_a?(UserFacingVersion)

    state ||= State.find_by(content_item: content_item)
    translation ||= Translation.find_by(content_item: content_item)
    location ||= Location.find_by(content_item: content_item)
    user_facing_version ||= UserFacingVersion.find_by(content_item: content_item)

    return unless state && translation && location && user_facing_version

    state_name = state.name
    locale = translation.locale
    base_path = location.base_path
    user_version = user_facing_version.number

    matching_items = ContentItemFilter.filter(
      state: state_name,
      locale: locale,
      base_path: base_path,
      user_version: user_version,
    )

    additional_items = matching_items - [content_item]

    if additional_items.any?
      error = "conflicts with a duplicate: "
      error << "state=#{state_name}, "
      error << "locale=#{locale}, "
      error << "base_path=#{base_path}, "
      error << "user_version=#{user_version}"

      record.errors.add(:content_item, error)
    end
  end
end

