class Translation < ApplicationRecord
  belongs_to :edition, foreign_key: "content_item_id"

  def self.filter(edition_scope, locale:)
    join_editions(edtion_scope)
      .where("translations.locale" => locale)
  end

  def self.join_editions(edition_scope)
    edition_scope.joins(
      "INNER JOIN translations ON translations.content_item_id = content_items.id"
    )
  end
end
