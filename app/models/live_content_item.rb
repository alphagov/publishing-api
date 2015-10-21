class LiveContentItem < ActiveRecord::Base
  include Replaceable
  include DefaultAttributes
  include SymbolizeJSON
  include ImmutableBasePath

  TOP_LEVEL_FIELDS = [
    :base_path,
    :content_id,
    :description,
    :details,
    :format,
    :locale,
    :public_updated_at,
    :publishing_app,
    :redirects,
    :rendering_app,
    :routes,
    :title,
  ].freeze

  belongs_to :draft_content_item

  validates :draft_content_item, presence: true
  validates :content_id, presence: true
  validate :content_ids_match

  def refreshed_draft_item
    if draft_content_item
      DraftContentItem.find_by(content_id: draft_content_item.content_id, locale: locale) || draft_content_item
    end
  end

private
  def self.query_keys
    [:content_id, :locale]
  end

  def content_ids_match
    if draft_content_item && draft_content_item.content_id != content_id
      errors.add(:content_id, "id mismatch between draft and live content items")
    end
  end
end
