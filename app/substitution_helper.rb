module SubstitutionHelper
  def self.clear_space!(draft_content_item, klass)
    existing_content_item = klass.find_by(base_path: draft_content_item.base_path)
    return unless existing_content_item

    mismatch = (existing_content_item.content_id != draft_content_item.content_id)
    allowed_to_substitute = (draft_content_item.substitute? || existing_content_item.substitute?)

    if mismatch && allowed_to_substitute
      existing_version = Version.find_by(target: existing_content_item)
      existing_version.destroy if existing_version
      existing_content_item.destroy
    end
  end
end
