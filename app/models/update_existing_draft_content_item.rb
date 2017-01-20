class UpdateExistingDraftContentItem
  ATTRIBUTES_PROTECTED_FROM_RESET = [
    :id,
    :document_id,
    :created_at,
    :updated_at,
    :first_published_at,
    :last_edited_at,
  ].freeze

  attr_reader :payload, :put_content, :content_item

  def initialize(content_item, put_content, payload)
    @content_item = content_item
    @put_content = put_content
    @payload = payload
  end

  def call
    update_lock_version
    update_content_item
  end

private

  def update_lock_version
    put_content.send(:check_version_and_raise_if_conflicting, document, payload[:previous_version])
    document.increment! :stale_lock_version
  end

  def document
    put_content.document
  end

  def update_content_item
    old_item = content_item.dup
    assign_attributes_with_defaults
    content_item.save!
    [content_item, old_item]
  end

  def assign_attributes_with_defaults
    content_item.assign_attributes(new_attributes)
  end

  def new_attributes
    content_item.class.column_defaults.symbolize_keys
      .merge(attributes.symbolize_keys)
      .except(*ATTRIBUTES_PROTECTED_FROM_RESET)
  end

  def attributes
    content_item_attributes_from_payload.merge(
      locale: payload.fetch(:locale, ContentItem::DEFAULT_LOCALE),
      state: "draft",
      content_store: "draft",
      user_facing_version: content_item.user_facing_version,
    )
  end

  def content_item_attributes_from_payload
    payload.slice(*ContentItem::TOP_LEVEL_FIELDS)
  end
end
