class Translation < ActiveRecord::Base
  belongs_to :content_item

  validates :locale, inclusion: {
    in: I18n.available_locales.map(&:to_s),
    message: 'must be a supported locale'
  }

  validates_with ContentItemUniquenessValidator

  def self.filter(content_item_scope, locale:)
    join_content_items(content_item_scope)
      .where("translations.locale" => locale)
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN translations ON translations.content_item_id = content_items.id"
    )
  end
end
