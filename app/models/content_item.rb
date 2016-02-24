class ContentItem < ActiveRecord::Base
  include DefaultAttributes
  include SymbolizeJSON
  include DescriptionOverrides

  DEFAULT_LOCALE = "en".freeze

  TOP_LEVEL_FIELDS = [
    :content_id,
    :description,
    :details,
    :format,
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

  NON_RENDERABLE_FORMATS = %w(redirect gone).freeze

  scope :renderable_content, -> { where.not(format: NON_RENDERABLE_FORMATS) }

  validates :content_id, presence: true, uuid: true
  validates :format, presence: true
  validates :publishing_app, presence: true
  validates :title, presence: true, if: :renderable_content?
  validates :rendering_app, presence: true, dns_hostname: true, if: :renderable_content?
  validates :phase, inclusion: {
    in: ['alpha', 'beta', 'live'],
    message: 'must be either alpha, beta, or live'
  }
  validates :description, well_formed_content_types: { must_include: "text/html" }
  validates :details, well_formed_content_types: { must_include: "text/html" }

  # Postgres's JSON columns have problems storing literal strings, so these
  # getter/setter wrap the description in a JSON object.
  def description=(value)
    super(value: value)
  end

  def description
    super.fetch(:value)
  end

  def attributes
    attributes = super
    description = attributes.delete("description")

    if description
      attributes.merge("description" => description.fetch("value"))
    else
      attributes
    end
  end

private

  def renderable_content?
    NON_RENDERABLE_FORMATS.exclude?(format)
  end
end
