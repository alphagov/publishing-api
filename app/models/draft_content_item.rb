class DraftContentItem < ActiveRecord::Base
  DEFAULT_LOCALE = "en".freeze

  include Replaceable
  include DefaultAttributes
  include SymbolizeJSON
  include ImmutableBasePath

  TOP_LEVEL_FIELDS = (LiveContentItem::TOP_LEVEL_FIELDS + [
    :access_limited,
  ]).freeze

  NON_RENDERABLE_FORMATS = %w(redirect gone)

  has_one :live_content_item

  scope :renderable_content, -> { where.not(format: NON_RENDERABLE_FORMATS) }

  validates :content_id, presence: true, uuid: true
  validate :content_ids_match
  validates :base_path, absolute_path: true
  validates :format, presence: true
  validates :publishing_app, presence: true
  validates :title, presence: true, if: :renderable_content?
  validates :rendering_app, presence: true, dns_hostname: true, if: :renderable_content?

private
  def self.query_keys
    [:content_id, :locale]
  end

  def content_ids_match
    if live_content_item && live_content_item.content_id != content_id
      errors.add(:content_id, "id mismatch between draft and live content items")
    end
  end

  def renderable_content?
    NON_RENDERABLE_FORMATS.exclude?(format)
  end
end
