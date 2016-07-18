class ContentItemUniquenessValidator < ActiveModel::Validator
  include ::Queries::ArelHelpers

  # def validate(record)
  #   content_item = record.content_item
  #
  #   state = record if record.is_a?(State)
  #   translation = record if record.is_a?(Translation)
  #   location = record if record.is_a?(Location)
  #   user_facing_version = record if record.is_a?(UserFacingVersion)
  #
  #   state ||= State.find_by(content_item: content_item)
  #   translation ||= Translation.find_by(content_item: content_item)
  #   location ||= Location.find_by(content_item: content_item)
  #   user_facing_version ||= UserFacingVersion.find_by(content_item: content_item)
  #
  #   return unless state && translation && location && user_facing_version
  #
  #   # We should only have one content item at a given path (and locale) for each
  #   # content store. Superseded content items aren't in either content store so
  #   # we can relax this validation.
  #   return if state.name == "superseded"
  #
  #   state_name = state.name
  #   locale = translation.locale
  #   base_path = location.base_path
  #   user_version = user_facing_version.number
  #
  #   matching_items = ContentItemFilter.filter(
  #     state: state_name,
  #     locale: locale,
  #     base_path: base_path,
  #     user_version: user_version,
  #   )
  #
  #   additional_items = matching_items - [content_item]
  #
  #   if additional_items.any?
  #     error = "conflicts with a duplicate: "
  #     error << "state=#{state_name}, "
  #     error << "locale=#{locale}, "
  #     error << "base_path=#{base_path}, "
  #     error << "user_version=#{user_version}, "
  #     error << "content_id=#{additional_items.first.content_id}"
  #
  #     record.errors.add(:content_item, error)
  #   end
  # end

  def validate(record)
    content_item = record.content_item
    pillars = pillars_for_content_item(content_item)

    return unless pillars

    state_name = record.is_a?(State) ? record.name : pillars["state_name"]
    locale = record.is_a?(Translation) ? record.locale : pillars["locale"]
    base_path = record.is_a?(Location) ? record.base_path : pillars["base_path"]
    user_version = record.is_a?(UserFacingVersion) ? record.number : pillars["user_version"]

    return unless [state_name, locale, base_path, user_version].all?

    # We should only have one content item at a given path (and locale) for each
    # content store. Superseded content items aren't in either content store so
    # we can relax this validation.
    return if state_name == "superseded"

    non_unique = pillars_for_unique_fields(content_item, state_name, locale, base_path, user_version)

    if non_unique
      error = "conflicts with a duplicate: "
      error << "state=#{state_name}, "
      error << "locale=#{locale}, "
      error << "base_path=#{base_path}, "
      error << "user_version=#{user_version}, "
      error << "content_id=#{non_unique["content_id"]}"

      record.errors.add(:content_item, error)
    end
  end

private

  def pillars_for_content_item(content_item)
    content_items_table = table(:content_items)

    scope = pillars_of_unique_scope
    scope.where(content_items_table[:content_id].eq(content_item.content_id))
    get_rows(scope).first
  end

  def pillars_for_unique_fields(content_item, state_name, locale, base_path, user_version)
    content_items_table = table(:content_items)
    states_table = table(:states)
    translations_table = table(:translations)
    locations_table = table(:locations)
    user_facing_versions_table = table(:user_facing_versions)

    scope = pillars_of_unique_scope
    scope
      .where(content_items_table[:id].not_eq(content_item.id))
      .where(states_table[:name].eq(state_name))
      .where(translations_table[:locale].eq(locale))
      .where(locations_table[:base_path].eq(base_path))
      .where(user_facing_versions_table[:number].eq(user_version))
    get_rows(scope).first
  end

  def pillars_of_unique_scope
    content_items_table = self.table(:content_items)
    states_table = self.table(:states)
    translations_table = self.table(:translations)
    locations_table = self.table(:locations)
    user_facing_versions_table = self.table(:user_facing_versions)

    content_items_table
      .project(
        content_items_table[:content_id],
        states_table[:name].as("state_name"),
        translations_table[:locale],
        locations_table[:base_path],
        user_facing_versions_table[:number].as("user_version")
      )
      .outer_join(states_table)
        .on(content_items_table[:id].eq(states_table[:content_item_id]))
      .outer_join(translations_table)
        .on(content_items_table[:id].eq(translations_table[:content_item_id]))
      .outer_join(locations_table)
        .on(content_items_table[:id].eq(locations_table[:content_item_id]))
      .outer_join(user_facing_versions_table)
        .on(content_items_table[:id].eq(user_facing_versions_table[:content_item_id]))
  end
end
