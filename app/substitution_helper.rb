module SubstitutionHelper
  SUBSTITUTABLE_DOCUMENT_TYPES = %w(
    coming_soon
    gone
    redirect
    unpublishing
    special_route
  ).freeze

  class << self
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

      blocking_items = ContentItemFilter.filter(base_path: base_path, locale: locale, state: state)

      blocking_items.each do |blocking_item|
        mismatch = (blocking_item.content_id != new_item_content_id)
        allowed_to_substitute = (substitute?(new_item_document_type) || substitute?(blocking_item.document_type))

        if mismatch && allowed_to_substitute
          if state == "draft"
            Commands::V2::DiscardDraft.call({
                content_id: blocking_item.content_id,
              },
              downstream: downstream,
              nested: nested,
              callbacks: callbacks,
            )
          else
            State.substitute(blocking_item)
          end
        end
      end
    end

  private

    def substitute?(document_type)
      SUBSTITUTABLE_DOCUMENT_TYPES.include?(document_type)
    end
  end

  class NilBasePathError < StandardError; end
end
