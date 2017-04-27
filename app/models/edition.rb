class Edition < ApplicationRecord
  include SymbolizeJSON

  enum content_store: {
    draft: 'draft',
    live: 'live'
  }

  DEFAULT_LOCALE = "en".freeze

  TOP_LEVEL_FIELDS = [
    :analytics_identifier,
    :base_path,
    :content_store,
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
    :state,
    :title,
    :user_facing_version,
    :update_type,
  ].freeze

  NON_RENDERABLE_FORMATS = %w(redirect gone).freeze
  EMPTY_BASE_PATH_FORMATS = %w(contact government).freeze

  belongs_to :document
  has_one :unpublishing
  has_one :change_note
  has_many :links

  scope :renderable_content, -> { where.not(document_type: NON_RENDERABLE_FORMATS) }
  scope :with_document, -> { joins(:document) }
  scope :with_unpublishing, -> { left_outer_joins(:unpublishing) }
  scope :with_change_note, -> { left_outer_joins(:change_note) }

  validates :document, presence: true

  validates :schema_name, presence: true
  validates :document_type, presence: true

  validates :base_path, absolute_path: true, if: :base_path_present?
  validates :publishing_app, presence: true
  validates :title, presence: true, if: :renderable_content?
  validates :rendering_app, presence: true, dns_hostname: true, if: :requires_rendering_app?
  validates :phase, inclusion: {
    in: %w(alpha beta live),
    message: 'must be either alpha, beta, or live'
  }
  validates :details, well_formed_content_types: { must_include_one_of: %w(text/html text/govspeak) }

  validate :user_facing_version_must_increase
  validate :draft_cannot_be_behind_live

  validates :routes, absence: true, if: -> (e) { e.schema_name == "redirect" }

  validates_with VersionForDocumentValidator
  validates_with BasePathForStateValidator
  validates_with StateForDocumentValidator
  validates_with RoutesAndRedirectsValidator

  delegate :content_id, :locale, to: :document

  def to_h
    SymbolizeJSON::symbolize(
      attributes.merge(
        api_path: api_path,
        api_url: api_url,
        web_url: web_url,
        withdrawn: withdrawn?,
        content_id: content_id,
        locale: locale,
      )
    )
  end

  def requires_base_path?
    EMPTY_BASE_PATH_FORMATS.exclude?(document_type)
  end

  def pathless?
    !self.requires_base_path? && !base_path
  end

  def base_path_present?
    base_path.present?
  end

  def draft_cannot_be_behind_live
    return unless document

    if state == "draft"
      draft_version = user_facing_version
      published_unpublished_version = document.published_or_unpublished.try(:user_facing_version)
    end

    if %w(published unpublished).include?(state)
      draft_version = document.draft.user_facing_version if document.draft
      published_unpublished_version = user_facing_version
    end

    return unless draft_version && published_unpublished_version

    if draft_version < published_unpublished_version
      mismatch = "(#{draft_version} < #{published_unpublished_version})"
      message = "draft edition cannot be behind the published/unpublished edition #{mismatch}"
      errors.add(:user_facing_version, message)
    end
  end

  def user_facing_version_must_increase
    return unless persisted?
    return unless user_facing_version_changed? && user_facing_version <= user_facing_version_was

    mismatch = "(#{user_facing_version} <= #{user_facing_version_was})"
    message = "cannot be less than or equal to the previous user_facing_version #{mismatch}"
    errors.add(:user_facing_version, message)
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

  def publish
    update_attributes!(state: "published", content_store: "live")
  end

  def supersede
    update_attributes!(state: "superseded", content_store: nil)
  end

  def unpublish(type:, explanation: nil, alternative_path: nil, redirects: nil, unpublished_at: nil)
    content_store = type == "substitute" ? nil : "live"
    update_attributes!(state: "unpublished", content_store: content_store)

    unpublished_at = nil unless type == "withdrawal"

    if unpublishing.present?
      unpublishing.update_attributes(
        type: type,
        explanation: explanation,
        alternative_path: alternative_path,
        redirects: redirects,
        unpublished_at: unpublished_at,
      )
      unpublishing
    else
      Unpublishing.create!(
        edition: self,
        type: type,
        explanation: explanation,
        alternative_path: alternative_path,
        redirects: redirects,
        unpublished_at: unpublished_at,
      )
    end
  end

  def substitute
    unpublish(
      type: "substitute",
      explanation: "Automatically unpublished to make way for another document",
    )
  end

  def unpublished?
    state == "unpublished" && unpublishing.present?
  end

  def gone?
    (unpublished? && unpublishing.gone?) || document_type == "gone"
  end

  def redirect?
    (unpublished? && unpublishing.redirect?) || document_type == "redirect"
  end

  def withdrawn?
    unpublished? && unpublishing.withdrawal?
  end

  def substitute?
    unpublished? && unpublishing.substitute?
  end

  def api_path
    return unless base_path
    "/api/content" + base_path
  end

  def api_url
    return unless api_path
    Plek.current.website_root + api_path
  end

  def web_url
    return unless base_path
    Plek.current.website_root + base_path
  end

  # We're keeping this until such time as we decide to remove description_json
  # entirely, so that we don't lose the data in case we decide to revert.
  def description=(value)
    super(value)
    self.description_json = { "value" => value }
  end

private

  def renderable_content?
    NON_RENDERABLE_FORMATS.exclude?(document_type)
  end

  def requires_rendering_app?
    renderable_content? && document_type != "contact"
  end
end
