module VersionValidator
  class Draft < ActiveModel::Validator
    def validate(draft_item)
      live_item = draft_item.live_content_item
      message = VersionValidator.validate(draft_item, live_item)
      draft_item.errors.add(:version, message) if message
    end
  end

  class Live < ActiveModel::Validator
    def validate(live_item)
      draft_item = live_item.draft_content_item
      message = VersionValidator.validate(draft_item, live_item)
      live_item.errors.add(:version, message) if message
    end
  end

  def self.validate(draft_item, live_item)
    return unless draft_item && live_item
    return unless draft_item.version && live_item.version

    if live_item.version > draft_item.version
      mismatch = "(#{live_item.version} > #{draft_item.version})"
      "cannot be greater than draft version #{mismatch}"
    end
  end
end
