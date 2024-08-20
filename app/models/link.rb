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
    if filters.size > 1
      # TODO: richard.towers - temporary warning to check whether this method is ever
      #       called with multiple filters. The code looks wrong, so if it's not being
      #       called we should make this an error and only support a single filter.
      logger.warn("filter_editions called with multiple filters. These will be ANDed together in a way that probably isn't what we want. Filters were: #{filters.inspect}")
    end

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
