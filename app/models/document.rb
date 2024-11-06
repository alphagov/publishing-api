class Document < ApplicationRecord
  include FindOrCreateLocked

  belongs_to :owning_document, class_name: "Document", optional: true
  has_many :editions
  has_one :link_set, primary_key: "content_id", foreign_key: "content_id", inverse_of: :documents
  has_many :link_set_links, class_name: "Link", through: :link_set, source: :links
  has_many :reverse_links,
           class_name: "Link",
           foreign_key: :target_content_id,
           primary_key: :content_id,
           inverse_of: :target_documents

  has_one :draft, -> { where(content_store: "draft") }, class_name: "Edition"
  has_one :live, -> { where(content_store: "live") }, class_name: "Edition"
  has_one :statistics_cache

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
