class UpdateExistingDraftEdition
  ATTRIBUTES_PROTECTED_FROM_RESET = [
    :id,
    :document_id,
    :content_id,
    :locale,
    :created_at,
    :updated_at,
    :last_edited_at,
  ].freeze

  attr_reader :payload, :put_content, :edition

  def initialize(edition, put_content, payload)
    @edition = edition
    @put_content = put_content
    @payload = payload
  end

  def call
    update_lock_version
    update_edition
  end

private

  def update_lock_version
    put_content.send(:check_version_and_raise_if_conflicting, document, payload[:previous_version])
    document.increment!(:stale_lock_version)
  end

  def document
    put_content.document
  end

  def update_edition
    old_edition = edition.dup
    presented_old_edition = presented_old_edition(edition.id)
    assign_attributes_with_defaults

    # The links are deleted here and then recreated from a payload in the
    # PutContent controller. This allows users to delete links simply by not
    # including them in the payload.
    edition.links.delete_all

    edition.save!
    [edition, old_edition, presented_old_edition]
  end

  def presented_old_edition(id)
    Presenters::DownstreamPresenter.present(
      Queries::GetWebContentItems.find(id),
      state_fallback_order: [:draft, :published]
    ).deep_stringify_keys
  end

  def assign_attributes_with_defaults
    edition.assign_attributes(attributes_from_payload)
  end

  def remove_first_published_at_if_not_explicitly_set(attributes)
    attributes.tap do |x|
      x.delete(:first_published_at) unless payload.include?(:first_published_at)
    end
  end

  def without_protected_attributes
    edition.class.column_defaults.symbolize_keys
      .merge(attributes.symbolize_keys)
      .except(*ATTRIBUTES_PROTECTED_FROM_RESET)
  end

  def attributes_from_payload
    remove_first_published_at_if_not_explicitly_set(
      without_protected_attributes
    )
  end

  def attributes
    edition_attributes_from_payload.merge(
      state: "draft",
      content_store: "draft",
      user_facing_version: edition.user_facing_version,
    )
  end

  def edition_attributes_from_payload
    payload.slice(*Edition::TOP_LEVEL_FIELDS)
  end
end
