class Translation < ApplicationRecord
  belongs_to :edition

  def self.filter(content_item_scope, locale:)
    join_content_items(content_item_scope)
      .where("translations.locale" => locale)
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN translations ON translations.edition_id = editions.id"
    )
  end
end
