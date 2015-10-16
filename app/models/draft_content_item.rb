class DraftContentItem < ActiveRecord::Base
  include Replaceable
  include DefaultAttributes
  include SymbolizeJSON
  include ImmutableBasePath

  TOP_LEVEL_FIELDS = (LiveContentItem::TOP_LEVEL_FIELDS + [
    :access_limited,
  ]).freeze

  has_one :live_content_item

  validates :content_id, presence: true
  validate :content_ids_match
  validates :version, presence: true

private
  def self.query_keys
    [:content_id, :locale]
  end

  def content_ids_match
    if live_content_item && live_content_item.content_id != content_id
      errors.add(:content_id, "id mismatch between draft and live content items")
    end
  end
end
