class ContentItemUniquenessValidator < ActiveModel::Validator
  def validate(record)
    content_item = ContentItem.with_supporting_objects.where(id: record.content_item_id).first
    return unless content_item

    state = record if record.is_a?(State)
    translation = record if record.is_a?(Translation)
    location = record if record.is_a?(Location)
    user_facing_version = record if record.is_a?(UserFacingVersion)

    state ||= content_item.state
    translation ||= content_item.translation
    location ||= content_item.location
    user_facing_version ||= content_item.user_facing_version

    return unless state && translation && location && user_facing_version

    # For now, we have agreed to relax the validator so that you can have
    # duplicates with a state of unpublished. The reason for doing this is because
    # we think that the 'gone' and 'redirect' mechanisms are modelled incorrect
    # and need to be revisited.
    #
    # As it stands right now, when these content items are sent to the
    # Publishing API, they have the side-effect of unpublishing other content
    # items. We think think that this should change in the future.
    return if state.name == "unpublished"

    state_name = state.name
    locale = translation.locale
    base_path = location.base_path
    user_version = user_facing_version.number

    other_content_items = ContentItem.where("content_items.id <> #{content_item.id}")
    matching_items = ContentItemFilter.new(scope: other_content_items).filter(
      state: state_name,
      locale: locale,
      base_path: base_path,
      user_version: user_version,
    )

    if matching_items.any?
      error = "conflicts with a duplicate: "
      error << "state=#{state_name}, "
      error << "locale=#{locale}, "
      error << "base_path=#{base_path}, "
      error << "user_version=#{user_version}"

      record.errors.add(:content_item, error)
    end
  end
end
