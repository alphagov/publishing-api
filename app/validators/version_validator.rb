module VersionValidator
  class Draft < ActiveModel::Validator
    def validate(draft_item)
      version_is_greater_than_live(draft_item)
      versions_cant_go_backwards(draft_item)
    end

    private

    def version_is_greater_than_live(draft_item)
      live_item = draft_item.refreshed_live_item

      return unless draft_item && live_item
      return unless draft_item.version && live_item.version

      if draft_item.version <= live_item.version
        mismatch = "(#{draft_item.version} <= #{live_item.version})"
        message = "cannot be less than or equal to live version #{mismatch}"
        draft_item.errors.add(:version, message)
      end
    end

    def versions_cant_go_backwards(draft_item)
      return unless draft_item.version && draft_item.version_was

      if draft_item.version <= draft_item.version_was
        difference = "(#{draft_item.version} <= #{draft_item.version_was})"
        message = "cannot be less than or equal to the previous draft version #{difference}"

        draft_item.errors.add(:version, message)
      end
    end
  end

  class Live < ActiveModel::Validator
    def validate(live_item)
      versions_are_equal(live_item)
    end

    def versions_are_equal(live_item)
      draft_item = live_item.refreshed_draft_item

      return unless draft_item && live_item
      return unless draft_item.version && live_item.version

      if live_item.version != draft_item.version
        mismatch = "(#{live_item.version} != #{draft_item.version})"
        message = "live and draft versions must be equal #{mismatch}"
        live_item.errors.add(:version, message)
      end
    end
  end
end
