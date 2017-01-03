class Document < ApplicationRecord
  has_many :content_items

  validates :content_id, presence: true, uuid: true

  validates :locale, inclusion: {
    in: I18n.available_locales.map(&:to_s),
    message: 'must be a supported locale'
  }

  def draft
    content_items.find_by(state: "draft")
  end

  def live
    content_items.find_by(state: %w(published unpublished))
  end
end
