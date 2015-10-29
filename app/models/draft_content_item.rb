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
  validates :public_updated_at, presence: true, if: :renderable_content?
  validate :route_set_is_valid
  validate :no_extra_route_keys
  validate :access_limited_is_valid
  validates :locale, inclusion: {
    in: I18n.available_locales.map(&:to_s),
    message: 'must be a supported locale'
  }

  def viewable_by?(user_uid)
    !access_limited? || authorised_user_uids.include?(user_uid)
  end

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

  def route_set_is_valid
    unless base_path.present? && registerable_route_set.valid?
      errors.set(:routes, registerable_route_set.errors[:registerable_routes])
      errors.set(:redirects, registerable_route_set.errors[:registerable_redirects])
    end
  end

  def registerable_route_set
    @registerable_route_set ||= RegisterableRouteSet.from_content_item(self)
  end

  def no_extra_route_keys
    if routes.any? { |r| (r.keys - [:path, :type]).any? }
      errors.add(:routes, "are invalid")
    end
    if redirects.any? { |r| (r.keys - [:path, :type, :destination]).any? }
      errors.add(:redirects, "are invalid")
    end
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
