class Link < ApplicationRecord
  include SymbolizeJSON

  belongs_to :link_set

  validate :link_type_is_valid
  validate :content_id_is_valid

  def self.filter_content_items(scope, filters)
    join_sql = <<-SQL.strip_heredoc
      INNER JOIN link_sets ON link_sets.content_id = content_items.content_id
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

  def link_type_is_valid
    unless link_type.match(/\A[a-z0-9_]+\z/) && link_type != "available_translations"
      errors.add(:link, "Invalid link type: #{link_type}")
    end
  end

  def content_id_is_valid
    unless target_content_id.is_a?(Hash) || UuidValidator.valid?(target_content_id)
      errors.add(:link, "target_content_id must be a valid UUID")
    end
  end
end
