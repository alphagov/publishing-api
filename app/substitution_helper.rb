module SubstitutionHelper
  extend self

  SUBSTITUTABLE_DOCUMENT_TYPES = %w(
    coming_soon
    gone
    redirect
    unpublishing
    special_route
  ).freeze

  SUBSTITUTABLE_UNPUBLISHING_TYPES = %w(gone redirect vanish).freeze

  def clear!(
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
        blocking_edition.substitute
      end
    end
  end

private

  def discard_draft(blocking_edition, downstream, nested, callbacks)
    Commands::V2::DiscardDraft.call(
      {
        content_id: blocking_edition.document.content_id,
        locale: blocking_edition.document.locale,
      },
      downstream: downstream,
      nested: nested,
      callbacks: callbacks
    )
  end

  def blocking_editions(base_path, state, locale, new_item_content_id, new_item_document_type)
    Edition
      .with_document
      .where(base_path: base_path, state: state, documents: { locale: locale })
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
