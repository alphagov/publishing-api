class Link < ApplicationRecord
  include SymbolizeJSON

  belongs_to :link_set, optional: true
  belongs_to :edition, optional: true

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
    join_sql = <<-SQL.strip_heredoc
      INNER JOIN link_sets ON link_sets.content_id = documents.content_id
      INNER JOIN links ON links.link_set_id = link_sets.id
    SQL

    scope = scope.joins(join_sql)

    filters.each do |link_type, target_content_id|
      scope = scope.where(
        "links.link_type": link_type,
        "links.target_content_id": target_content_id,
      )
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
