module SubstitutionHelper
  extend self

  SUBSTITUTABLE_DOCUMENT_TYPES = %w[
    coming_soon
    gone
    redirect
    unpublishing
    special_route
  ].freeze

  SUBSTITUTABLE_UNPUBLISHING_TYPES = %w[gone redirect vanish].freeze

  def clear_items_of_same_locale_and_base_path!(
    new_item_document_type:,
    new_item_content_id:,
    base_path:,
    locale:,
    state:,
    downstream: true,
    callbacks: [],
    nested: false
  )
    raise NilBasePathError if base_path.nil?

    blocking_editions(
      base_path, state, locale, new_item_content_id, new_item_document_type
    ).each do |blocking_edition|
      if state == "draft"
        discard_draft(blocking_edition, downstream, nested, callbacks)
      else
        substitute_edition(blocking_edition)
      end
    end
  end

  def clear_item_of_different_locale_but_matching_base_path!(
    base_path:,
    content_id:,
    locale:,
    state:,
    downstream: true,
    callbacks: []
  )
    return unless base_path

    edition_for_different_locale = Edition.with_document
      .where(documents: { content_id: }, state:, base_path:)
      .where.not(documents: { locale: })
      .first

    return unless edition_for_different_locale

    if state == "published"
      # This enables changing the locale of some content where a
      # published edition for the previous locale still exists.
      substitute_edition(edition_for_different_locale)
    elsif state == "draft"
      # This enables changing the locale of some content where a
      # draft for the previous locale still exists.
      discard_draft(edition_for_different_locale, downstream, true, callbacks)
    else
      raise "Unexpected state #{state}"
    end
  end

private

  def substitute_edition(edition)
    edition.substitute
    payload = DownstreamPayload.new(edition, Event.maximum_id)
    DownstreamService.broadcast_to_message_queue(payload, "unpublish")
  end

  def discard_draft(blocking_edition, downstream, nested, callbacks)
    Commands::V2::DiscardDraft.call(
      {
        content_id: blocking_edition.document.content_id,
        locale: blocking_edition.document.locale,
      },
      downstream:,
      nested:,
      callbacks:,
    )
  end

  def blocking_editions(base_path, state, locale, new_item_content_id, new_item_document_type)
    Edition
      .with_document
      .where(base_path:, state:, documents: { locale: })
      .where.not(documents: { content_id: new_item_content_id })
      .select do |edition|
        can_substitute_document_type?(new_item_document_type) ||
          can_substitute?(edition)
      end
  end

  def can_substitute_document_type?(document_type)
    SUBSTITUTABLE_DOCUMENT_TYPES.include?(document_type)
  end

  def can_substitute_unpublishing_type?(unpublishing_type)
    SUBSTITUTABLE_UNPUBLISHING_TYPES.include?(unpublishing_type)
  end

  def can_substitute?(edition)
    return true if edition.unpublished? && can_substitute_unpublishing_type?(edition.unpublishing.type)

    can_substitute_document_type?(edition.document_type)
  end

  class NilBasePathError < StandardError; end
end
