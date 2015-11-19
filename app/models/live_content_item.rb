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
    :analytics_identifier,
    :phase,
    :update_type,
    :need_ids,
  ].freeze

  NON_RENDERABLE_FORMATS = %w(redirect gone)

  belongs_to :draft_content_item

  scope :renderable_content, -> { where.not(format: NON_RENDERABLE_FORMATS) }

  validates :content_id, presence: true, uuid: true
  validate :content_ids_match
  validates :base_path, presence: true, absolute_path: true
  validates :format, presence: true
  validates :publishing_app, presence: true
  validates :title, presence: true, if: :renderable_content?
  validates :rendering_app, presence: true, dns_hostname: true, if: :renderable_content?
  validates :public_updated_at, presence: true, if: :renderable_content?
  validates :locale, inclusion: {
    in: I18n.available_locales.map(&:to_s),
    message: 'must be a supported locale'
  }
  validates :phase, inclusion: {
    in: ['alpha', 'beta', 'live'],
    message: 'must be either alpha, beta, or live'
  }
  validates_with RoutesAndRedirectsValidator
  validates :description, well_formed_content_types: { must_include: "text/html" }
  validates :details, well_formed_content_types: { must_include: "text/html" }

  def published?
    true
  end

  # Postgres's JSON columns have problems storing literal strings, so these
  # getter/setter overrides wrap and unwrap those strings in hashes.
  def description=(value)
    if value.is_a?(String)
      super(string: value)
    else
      super
    end
  end

  def description
    value = super

    if value.is_a?(Hash) && value.key?(:string)
      value.fetch(:string)
    else
      value
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

  def renderable_content?
    NON_RENDERABLE_FORMATS.exclude?(format)
  end
end
