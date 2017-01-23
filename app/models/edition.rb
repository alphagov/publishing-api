class Edition < ApplicationRecord
  self.table_name = "content_items"

  include DefaultAttributes
  include SymbolizeJSON
  include DescriptionOverrides

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
  has_one :unpublishing, foreign_key: "content_item_id"

  scope :renderable_content, -> { where.not(document_type: NON_RENDERABLE_FORMATS) }

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
  validates :description, well_formed_content_types: { must_include: "text/html" }
  validates :details, well_formed_content_types: { must_include_one_of: %w(text/html text/govspeak) }

  validate :user_facing_version_must_increase
  validate :draft_cannot_be_behind_live

  validates_with VersionForDocumentValidator
  validates_with BasePathForStateValidator
  validates_with StateForDocumentValidator
  validates_with RoutesAndRedirectsValidator

  # Temporary code until we remove content_id and locale fields
  before_save do
    next unless document
    self.content_id = document.content_id unless content_id == document.content_id
    self.locale = document.locale unless locale == document.locale
  end

  after_save do
    lock_version = LockVersion.find_or_create_by(target: self)
    if document.stale_lock_version < lock_version.number
      lock_version.update! number: document.stale_lock_version
    end
  end

  # Temporary code until we kill Location, State, Translation, and
  # UserFacingVersion
  after_save do
    if changes[:base_path] && changes[:base_path].last
      Location.find_or_initialize_by(content_item_id: id)
        .update!(base_path: changes[:base_path].last)
    end

    if changes[:base_path] && !changes[:base_path].last
      Location.find_by(content_item_id: id).try(:destroy)
    end

    if changes[:state]
      State.find_or_initialize_by(content_item_id: id)
        .update!(name: changes[:state].last)
    end

    if changes[:locale]
      Translation.find_or_initialize_by(content_item_id: id)
        .update!(locale: changes[:locale].last)
    end

    if changes[:user_facing_version]
      UserFacingVersion.find_or_initialize_by(content_item_id: id)
        .update!(number: changes[:user_facing_version].last)
    end
  end

  before_save { ensure_document }

  def document_requires_updating?
    !document || document.locale != locale || document.content_id != content_id
  end

  def ensure_document
    if document_requires_updating?
      self.document = Document.find_or_create_by(content_id: content_id,
                                                 locale: locale)
    end
  end

  def as_json(options = {})
    %i[content_id locale].each do |field|
      next if Array.wrap(options[:methods]).include?(field)
      only = Array.wrap(options[:only]) || []
      except = Array.wrap(options[:except]) || []
      if (only.empty? || only.include?(field)) && (except.empty? || !except.include?(field))
        options[:methods] = (options[:methods] || []) + [field]
      end
    end
    super(options)
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
      message = "draft content item cannot be behind the published/unpublished content item #{mismatch}"
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

  def unpublish(type:, explanation: nil, alternative_path: nil, unpublished_at: nil)
    content_store = type == "substitute" ? nil : "live"
    update_attributes!(state: "unpublished", content_store: content_store)

    unpublishing = Unpublishing.find_by(edition: self)

    unpublished_at = nil unless type == "withdrawal"

    if unpublishing.present?
      unpublishing.update_attributes(
        type: type,
        explanation: explanation,
        alternative_path: alternative_path,
        unpublished_at: unpublished_at,
      )
      unpublishing
    else
      Unpublishing.create!(
        edition: self,
        type: type,
        explanation: explanation,
        alternative_path: alternative_path,
        unpublished_at: unpublished_at,
      )
    end
  end

  def substitute
    unpublish(
      type: "substitute",
      explanation: "Automatically unpublished to make way for another content item",
    )
  end

private

  # These are private whilst they are legacy attributes, that are currently
  # kept for easy rollback to a previous iteration of the codebase
  def content_id
    self[:content_id]
  end

  def content_id=(val)
    write_attribute(:content_id, val)
  end

  def locale
    self[:locale]
  end

  def locale=(val)
    write_attribute(:locale, val)
  end

  def renderable_content?
    NON_RENDERABLE_FORMATS.exclude?(document_type)
  end

  def requires_rendering_app?
    renderable_content? && document_type != "contact"
  end
end
