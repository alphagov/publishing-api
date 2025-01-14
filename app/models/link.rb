class Link < ApplicationRecord
  include SymbolizeJSON

  belongs_to :link_set, optional: true
  belongs_to :edition, optional: true

  # NOTE: links can have more than one source / target document, because there
  # can be multiple documents with the same content_id and different locales
  has_many :source_documents, class_name: "Document", through: :link_set, source: :documents
  has_many :target_documents, class_name: "Document", primary_key: :target_content_id, foreign_key: :content_id

  validates :target_content_id, presence: true, uuid: true
  validate :link_type_is_valid
  validate :association_presence

  def self.filter_editions(scope, filters)
    raise "filter_editions doesn't support multiple filters" if filters.size > 1

    scope = scope.joins(document: :link_set_links)

    filters.each do |link_type, target_content_id|
      scope = scope.where(links: { link_type:, target_content_id: })
    end

    scope
  end

private

  VALID_LINK_TYPE_REGEX = /\A[a-z0-9_]+\z/
  AUTOMATIC_LINK_TYPES = %w[available_translations].freeze

  def association_presence
    if link_set.blank? && edition.blank?
      errors.add(:base, "must have a link set or an edition")
    elsif link_set.present? && edition.present?
      errors.add(:base, "must be associated with a link set or an edition, not both")
    end
  end

  def link_type_is_valid
    if !link_type.match(VALID_LINK_TYPE_REGEX) || AUTOMATIC_LINK_TYPES.include?(link_type)
      errors.add(:link, "Invalid link type: #{link_type}")
    end
  end
end
