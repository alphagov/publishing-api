class Edition < ApplicationRecord
  include SymbolizeJSON

  enum :content_store, draft: "draft", live: "live"

  DEFAULT_LOCALE = "en".freeze

  TOP_LEVEL_FIELDS = %i[
    analytics_identifier
    auth_bypass_ids
    base_path
    content_store
    description
    details
    document_type
    first_published_at
    last_edited_at
    last_edited_by_editor_id
    major_published_at
    phase
    public_updated_at
    published_at
    publishing_app
    publishing_api_first_published_at
    publishing_api_last_edited_at
    redirects
    rendering_app
    routes
    schema_name
    state
    title
    user_facing_version
    update_type
  ].freeze

  NON_RENDERABLE_FORMATS = %w[redirect gone].freeze
  NO_RENDERING_APP_FORMATS = %w[contact external_content role_appointment world_location].freeze
  CONTENT_BLOCK_PREFIX = "content_block".freeze

  belongs_to :document
  has_one :unpublishing
  has_one :change_note
  has_many :links, dependent: :delete_all

  scope :renderable_content, -> { where.not(document_type: NON_RENDERABLE_FORMATS) }
  scope :with_document, -> { joins(:document) }
  scope :with_unpublishing, -> { left_outer_joins(:unpublishing) }
  scope :with_change_note, -> { left_outer_joins(:change_note) }

  validates :document, presence: true

  validate :auth_bypass_ids_are_uuids

  validates :schema_name, presence: true
  validates :document_type, presence: true

  validates :base_path, absolute_path: true, if: :base_path_present?
  validates :publishing_app, presence: true
  validates :title, presence: true, if: :renderable_content?
  validates :rendering_app, presence: true, dns_hostname: true, if: :requires_rendering_app?
  validates :phase,
            inclusion: {
              in: %w[alpha beta live],
              message: "must be either alpha, beta, or live",
            }
  validates :details, well_formed_content_types: { must_include_one_of: %w[text/html text/govspeak] }

  validate :user_facing_version_must_increase
  validate :draft_cannot_be_behind_live

  validates :routes, absence: true, if: ->(edition) { edition.schema_name == "redirect" }

  validates_with VersionForDocumentValidator
  validates_with BasePathForStateValidator
  validates_with StateForDocumentValidator
  validates_with RoutesAndRedirectsValidator

  def self.attribute_or_delegate(*names, to:)
    names.each do |name|
      define_method(name) do
        attribute(name.to_s) || method(to).call.method(name).call
      end
    end
  end

  attribute_or_delegate :content_id, :locale, to: :document

  def auth_bypass_ids_are_uuids
    unless auth_bypass_ids.all? { |id| UuidValidator.valid?(id) }
      errors.add(:auth_bypass_ids, ["contains invalid UUIDs"])
    end
  end

  def to_h
    SymbolizeJSON.symbolize(
      attributes.merge(
        api_path:,
        api_url:,
        web_url:,
        withdrawn: withdrawn?,
        content_id:,
        locale:,
      ),
    )
  end

  def pathless?
    !base_path
  end

  delegate :present?, to: :base_path, prefix: true

  def draft_cannot_be_behind_live
    return unless document

    if draft?
      draft_version = user_facing_version
      published_unpublished_version = document.published_or_unpublished.try(:user_facing_version)
    end

    if %w[published unpublished].include?(state)
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

  def publish
    update!(state: "published", content_store: "live")
  end

  def supersede
    update!(state: "superseded", content_store: nil)
  end

  def unpublish(type:, explanation: nil, alternative_path: nil, redirects: nil, unpublished_at: nil)
    content_store = type == "substitute" ? nil : "live"
    update!(state: "unpublished", content_store:)

    if unpublishing.present?
      unpublishing.update!(
        type:,
        explanation:,
        alternative_path:,
        redirects:,
        unpublished_at:,
      )
      unpublishing
    else
      Unpublishing.create!(
        edition: self,
        type:,
        explanation:,
        alternative_path:,
        redirects:,
        unpublished_at:,
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

  def draft?
    content_store == "draft"
  end

  def api_path
    return unless base_path

    "/api/content#{base_path}"
  end

  def api_url
    return unless api_path

    Plek.website_root + api_path
  end

  def web_url
    return unless base_path

    Plek.website_root + base_path
  end

  def is_content_block?
    document_type.start_with?(CONTENT_BLOCK_PREFIX)
  end

private

  def renderable_content?
    NON_RENDERABLE_FORMATS.exclude?(document_type)
  end

  def requires_rendering_app?
    !is_content_block? && renderable_content? && NO_RENDERING_APP_FORMATS.exclude?(document_type)
  end
end
