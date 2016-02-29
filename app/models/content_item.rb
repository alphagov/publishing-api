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

  validates_with SchemaNameFormatValidator
  validates :content_id, presence: true, uuid: true
  validates :publishing_app, presence: true
  validates :title, presence: true, if: :renderable_content?
  validates :rendering_app, presence: true, dns_hostname: true, if: :renderable_content?
  validates :phase, inclusion: {
    in: %w(alpha beta live),
    message: 'must be either alpha, beta, or live'
  }
  validates :description, well_formed_content_types: { must_include: "text/html" }
  validates :details, well_formed_content_types: { must_include: "text/html" }

  before_save :convert_format

private

  def renderable_content?
    NON_RENDERABLE_FORMATS.exclude?(format)
  end

  def convert_format
    if format.present?
      self.document_type = format if document_type.blank?
      self.schema_name = format if schema_name.blank?
    elsif schema_name.present?
      self.format = schema_name
    end
  end
end
