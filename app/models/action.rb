class Action < ApplicationRecord
  belongs_to :edition, optional: true
  belongs_to :link_set, optional: true, foreign_key: :content_id, primary_key: :content_id
  belongs_to :event

  validates :action, presence: true

  def self.create_put_content_action(updated_draft, locale, event)
    create_publishing_action("PutContent", updated_draft, locale, event)
  end

  def self.create_publish_action(edition, locale, event)
    create_publishing_action("Publish", edition, locale, event)
  end

  def self.create_republish_action(edition, locale, event)
    create_publishing_action("Republish", edition, locale, event)
  end

  def self.create_unpublish_action(edition, unpublishing_type, locale, event)
    action = "Unpublish#{unpublishing_type.camelize}"
    create_publishing_action(action, edition, locale, event)
  end

  def self.create_discard_draft_action(edition, locale, event)
    create_publishing_action("DiscardDraft", edition, locale, event)
  end

  def self.create_publishing_action(action, edition, locale, event)
    create!(
      content_id: edition.document.content_id,
      locale:,
      action:,
      user_uid: event.user_uid,
      edition:,
      event:,
    )
  end

  def self.create_patch_link_set_action(link_set, before_links, event)
    action = create!(
      content_id: link_set.content_id,
      locale: nil,
      action: "PatchLinkSet",
      user_uid: event.user_uid,
      event:,
    )

    after_links = link_set.links.to_a
    LinkChangeService.new(action, before_links, after_links).record
  end
end
