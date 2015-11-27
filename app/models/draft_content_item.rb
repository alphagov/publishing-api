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
  validates :base_path, presence: true, absolute_path: true
  validates :format, presence: true
  validates :publishing_app, presence: true
  validates :title, presence: true, if: :renderable_content?
  validates :rendering_app, presence: true, dns_hostname: true, if: :renderable_content?
  validates :public_updated_at, presence: true, if: :renderable_content?
  validate :access_limited_is_valid
  validates :locale, inclusion: {
    in: I18n.available_locales.map(&:to_s),
    message: 'must be a supported locale'
  }
  validates :phase, inclusion: {
    in: ['alpha', 'beta', 'live'],
    message: 'must be either alpha, beta, or live'
  }
  validates_with RoutesAndRedirectsValidator

  def viewable_by?(user_uid)
    !access_limited? || authorised_user_uids.include?(user_uid)
  end

  def published?
    live_content_item.present?
  end

  def self.query_keys
    [:content_id, :locale]
  end

private
  def content_ids_match
    if live_content_item && live_content_item.content_id != content_id
      errors.add(:content_id, "id mismatch between draft and live content items")
    end
  end

  def renderable_content?
    NON_RENDERABLE_FORMATS.exclude?(format)
  end

  def access_limited_is_valid
    if access_limited? && (!access_limited_keys_valid? || !access_limited_values_valid?)
      errors.set(:access_limited, ['is not valid'])
    end
  end

  def access_limited_keys_valid?
    access_limited.keys == [:users]
  end

  def access_limited_values_valid?
    authorised_user_uids.is_a?(Array) && authorised_user_uids.all? { |id| id.is_a?(String) }
  end

  def authorised_user_uids
    access_limited[:users]
  end
end
