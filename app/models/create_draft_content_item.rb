class CreateDraftContentItem
  def initialize(put_content, payload, previously_published_item)
    @put_content = put_content
    @payload = payload
    @previously_published_item = previously_published_item
  end

  def call
    content_item.tap do
      fill_out_new_content_item
    end
  end

private

  attr_reader :payload, :put_content, :previously_published_item

  def content_item
    @content_item ||= create_content_item
  end

  def create_content_item
    attributes = content_item_attributes_from_payload.merge(
      state: "draft",
      content_store: "draft",
      user_facing_version: user_facing_version_number_for_new_draft,
    )
    document.content_items.create!(attributes)
  end

  def user_facing_version_number_for_new_draft
    previously_published_item.user_facing_version
  end

  def document
    put_content.document
  end

  def fill_out_new_content_item
    document.increment! :stale_lock_version
    ensure_link_set_exists

    set_first_published_at
  end

  def ensure_link_set_exists
    link_set = LinkSet.find_or_create_by!(content_id: document.content_id)
    if link_set.stale_lock_version == 0
      link_set.increment! :stale_lock_version
    end
  end

  def set_first_published_at
    return unless previously_published_item.set_first_published_at?
    return if content_item.first_published_at
    content_item.update_attributes(
      first_published_at: previously_published_item.first_published_at,
    )
  end

  def content_item_attributes_from_payload
    payload.slice(*ContentItem::TOP_LEVEL_FIELDS)
  end
end
