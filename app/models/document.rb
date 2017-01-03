class Document < ApplicationRecord
  include FindOrCreateLocked

  has_many :content_items
  has_one :draft, -> { where(content_store: "draft") }, class_name: ContentItem
  has_one :live, -> { where(content_store: "live") }, class_name: ContentItem

  validates :content_id, presence: true, uuid: true

  validates :locale, inclusion: {
    in: I18n.available_locales.map(&:to_s),
    message: 'must be a supported locale'
  }

  def previous
    content_items.find_by(state: %w(published unpublished))
  end
end
