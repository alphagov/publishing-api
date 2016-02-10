module SubstitutionHelper
  class << self
    def clear!(new_item_format:, new_item_content_id:, base_path:, locale:, state:)
      blocking_items = ContentItemFilter.filter(base_path: base_path, locale: locale, state: state)

      blocking_items.each do |blocking_item|
        mismatch = (blocking_item.content_id != new_item_content_id)
        allowed_to_substitute = (substitute?(new_item_format) || substitute?(blocking_item.format))

        if mismatch && allowed_to_substitute
          State.withdraw(blocking_item)
        end
      end
    end

  private

    def substitute?(format)
      %w(gone redirect unpublishing).include?(format)
    end
  end
end
