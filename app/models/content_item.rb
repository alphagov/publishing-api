class ContentItem < ApplicationRecord
  include DefaultAttributes
  include SymbolizeJSON
  include DescriptionOverrides

  DEFAULT_LOCALE = "en".freeze

  TOP_LEVEL_FIELDS = [
    :analytics_identifier,
    :content_id,
    :description,
    :details,
    :document_type,
    :first_published_at,
    :last_edited_at,
    :need_ids,
    :phase,
    :public_updated_at,
    :publishing_app,
    :redirects,
    :rendering_app,
    :routes,
    :schema_name,
    :title,
    :update_type,
  ].freeze

  NON_RENDERABLE_FORMATS = %w(redirect gone).freeze
  EMPTY_BASE_PATH_FORMATS = %w(contact government).freeze

  scope :renderable_content, -> { where.not(document_type: NON_RENDERABLE_FORMATS) }

  validates :schema_name, presence: true
  validates :document_type, presence: true

  validates :base_path, absolute_path: true, if: :base_path_present?
  validates :content_id, presence: true, uuid: true
  validates :publishing_app, presence: true
  validates :title, presence: true, if: :renderable_content?
  validates :rendering_app, presence: true, dns_hostname: true, if: :requires_rendering_app?
  validates :phase, inclusion: {
    in: %w(alpha beta live),
    message: 'must be either alpha, beta, or live'
  }
  validates :description, well_formed_content_types: { must_include: "text/html" }
  validates :details, well_formed_content_types: { must_include_one_of: %w(text/html text/govspeak) }

  validates :locale, inclusion: {
    in: I18n.available_locales.map(&:to_s),
    message: 'must be a supported locale'
  }

  validates_with VersionForLocaleValidator
  validates_with BasePathForStateValidator
  validates_with StateForLocaleValidator

  def requires_base_path?
    EMPTY_BASE_PATH_FORMATS.exclude?(document_type)
  end

  def pathless?
    !self.requires_base_path? && !base_path
  end

  def base_path_present?
    base_path.present?
  end

  # FIXME: This method is used to retrieve a version of .details that doesn't
  # have text/html, thus this can be used to convert the item to HTML
  # It is here for comparing our Govspeak output with that that was provided to
  # us previously and can be removed once we have migrated most applications.
  def details_for_govspeak_conversion
    return details unless details.is_a?(Hash)

    value_without_html = lambda do |value|
      wrapped = Array.wrap(value)
      html = wrapped.find { |item| item.is_a?(Hash) && item[:content_type] == "text/html" }
      govspeak = wrapped.find { |item| item.is_a?(Hash) && item[:content_type] == "text/govspeak" }
      if html.present? && govspeak.present?
        wrapped - [html]
      else
        value
      end
    end

    details.deep_dup.each_with_object({}) do |(key, value), memo|
      memo[key] = value_without_html.call(value)
    end
  end

private

  def renderable_content?
    NON_RENDERABLE_FORMATS.exclude?(document_type)
  end

  def requires_rendering_app?
    renderable_content? && document_type != "contact"
  end
end
