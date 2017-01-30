class Link < ApplicationRecord
  include SymbolizeJSON

  belongs_to :link_set
  belongs_to :edition, foreign_key: "content_item_id"

  validates :target_content_id, presence: true
  validate :link_type_is_valid
  validate :association_presence

  def self.filter_editions(scope, filters)
    join_sql = <<-SQL.strip_heredoc
      INNER JOIN link_sets ON link_sets.content_id = documents.content_id
      INNER JOIN links ON links.link_set_id = link_sets.id
    SQL

    scope = scope.joins(join_sql)

    filters.each do |link_type, target_content_id|
      scope = scope.where("links.link_type": link_type,
                          "links.target_content_id": target_content_id)
    end

    scope
  end

private

  def association_presence
    if link_set.blank? && edition.blank?
      errors.add(:base, "must have a link set or an edition")
    elsif link_set.present? && edition.present?
      errors.add(:base, "must be associated with a link set or an edition, not both")
    end
  end

  def link_type_is_valid
    unless link_type.match(/\A[a-z0-9_]+\z/) && link_type != "available_translations"
      errors.add(:link, "Invalid link type: #{link_type}")
    end
  end
end
