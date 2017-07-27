class ExpandedLinks < ApplicationRecord
  include FindOrCreateLocked

  def self.locked_update(
    content_id:,
    locale:,
    with_drafts:,
    payload_version:,
    expanded_links:
  )
    transaction do
      entry = find_or_create_locked(
        content_id: content_id,
        locale: locale,
        with_drafts: with_drafts,
      )

      next unless entry.payload_version <= payload_version

      entry.update!(
        payload_version: payload_version,
        expanded_links: expanded_links,
      )
    end
  end
end
