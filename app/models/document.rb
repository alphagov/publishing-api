class Document < ApplicationRecord
  include FindOrCreateLocked

  belongs_to :owning_document, class_name: "Document", optional: true
  has_many :editions
  has_many :links, primary_key: "content_id", foreign_key: "target_content_id"
  has_one :draft, -> { where(content_store: "draft") }, class_name: "Edition"
  has_one :live, -> { where(content_store: "live") }, class_name: "Edition"

  # Due to the scenario of unpublished type substitute we need a scope that
  # can access published / unpublished which isn't tied to live content store
  # FIXME - we should make this go away
  has_one :published_or_unpublished, -> { where(state: %w[published unpublished]) }, class_name: "Edition"

  scope :presented, -> { joins(:editions).where.not(editions: { content_store: nil }) }

  validates :content_id, presence: true, uuid: true

  validates :locale,
            inclusion: {
              in: I18n.available_locales.map(&:to_s),
              message: "must be a supported locale",
            }
end
