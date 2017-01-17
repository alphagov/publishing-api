class Document < ApplicationRecord
  include FindOrCreateLocked

  has_many :content_items
  has_one :draft, -> { where(content_store: "draft") }, class_name: ContentItem
  has_one :live, -> { where(content_store: "live") }, class_name: ContentItem

  # Due to the scenario of unpublished type substitute we need a scope that
  # can access published / unpublished which isn't tied to live content store
  # FIXME - we should make this go away
  has_one :published_or_unpublished, -> { where(state: %w(published unpublished)) }, class_name: ContentItem

  validates :content_id, presence: true, uuid: true

  validates :locale, inclusion: {
    in: I18n.available_locales.map(&:to_s),
    message: 'must be a supported locale'
  }
end
