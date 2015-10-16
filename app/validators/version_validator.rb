class VersionValidator < ActiveModel::Validator
  def validate(live_item)
    draft_item = live_item.draft_content_item
    return unless live_item.version && draft_item && draft_item.version

    if live_item.version > draft_item.version
      mismatch = "(#{live_item.version} > #{draft_item.version})"
      message = "cannot be greater than draft version #{mismatch}"

      live_item.errors.add(:version, message)
    end
  end
end
