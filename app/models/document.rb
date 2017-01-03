class Document < ApplicationRecord
  has_many :content_items

  validates :content_id, presence: true, uuid: true

  validates :locale, inclusion: {
    in: I18n.available_locales.map(&:to_s),
    message: 'must be a supported locale'
  }

  def draft
    draft_items = content_items.where(content_store: "draft")

    if draft_items.size > 1
      raise "There should only be one draft item"
    end

    draft_items.first
  end

  def live
    live_items = content_items.where(content_store: "live")

    if live_items.size > 1
      raise "There should only be one previous published or unpublished item"
    end

    live_items.first
  end
end
