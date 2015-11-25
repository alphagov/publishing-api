module SubstitutionHelper
  class << self
    def clear_draft!(draft_content_item)
      if clear!(draft_content_item, DraftContentItem)
        clear_foreign_key!(draft_content_item)
      end
    end

    def clear_live!(draft_content_item)
      clear!(draft_content_item, LiveContentItem)
    end

  private
    def clear!(draft_content_item, klass)
      existing_content_item = klass.find_by(base_path: draft_content_item.base_path)
      return unless existing_content_item

      mismatch = (existing_content_item.content_id != draft_content_item.content_id)
      allowed_to_substitute = (draft_content_item.substitute? || existing_content_item.substitute?)

      if mismatch && allowed_to_substitute
        existing_version = Version.find_by(target: existing_content_item)
        existing_version.destroy if existing_version
        existing_content_item.destroy
        return true
      end

      false
    end

    def clear_foreign_key!(draft_content_item)
      live_content_item = LiveContentItem.find_by(base_path: draft_content_item.base_path)
      return unless live_content_item

      live_content_item.update!(draft_content_item: nil)
    end
  end
end
