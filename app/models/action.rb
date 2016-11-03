class Action < ActiveRecord::Base
  belongs_to :content_item
  belongs_to :link_set
  belongs_to :event

  validate :one_of_content_item_link_set

  def self.create_put_content_action(content_item, locale, event)
    create_publishing_action("PutContent", content_item, locale, event)
  end

  def self.create_publish_action(content_item, locale, event)
    create_publishing_action("Publish", content_item, locale, event)
  end

  def self.create_unpublish_action(content_item, unpublishing_type, locale, event)
    action = "Unpublish#{unpublishing_type.camelize}"
    create_publishing_action(action, content_item, locale, event)
  end

  def self.create_discard_draft_action(content_item, locale, event)
    create_publishing_action("DiscardDraft", content_item, locale, event)
  end

  def self.create_publishing_action(action, content_item, locale, event)
    create!(
      content_id: content_item.content_id,
      locale: locale,
      action: action,
      user_uid: event.user_uid,
      content_item: content_item,
      event: event,
    )
  end

  def self.create_patch_link_set_action(link_set, event)
    create!(
      content_id: link_set.content_id,
      locale: nil,
      action: "PatchLinkSet",
      user_uid: event.user_uid,
      link_set: link_set,
      event: event,
    )
  end

private

  def one_of_content_item_link_set
    if content_item_id && link_set_id || content_item && link_set
      errors.add(:base, "can not be associated with both a content item and link set")
    end
  end
end
