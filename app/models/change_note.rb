class ChangeNote < ActiveRecord::Base
  belongs_to :content_item

  def self.create_from_content_item(payload, content_item)
    ChangeNoteFactory.new(payload, content_item).build
  end
end

class ChangeNoteFactory
  def initialize(payload, content_item)
    @payload = payload
    @content_item = content_item
  end

  def build
    return unless content_item.update_type == "major"
    create_from_top_level_change_note ||
      create_from_details_hash_change_note ||
      create_from_details_hash_change_history
  end

private

  attr_reader :payload, :content_item

  def create_from_top_level_change_note
    return unless change_note
    ChangeNote.create!(change_note.merge(content_item: content_item))
  end

  def create_from_details_hash_change_note
    return unless note
    ChangeNote.create!(
      content_item: content_item,
      public_timestamp: content_item.updated_at,
      note: note,
    )
  end

  def create_from_details_hash_change_history
    return unless history
    history_element = history.sort_by { |h| h[:public_timestamp] }.last
    ChangeNote.create!(history_element.merge(content_item: content_item))
  end

  def change_note
    payload[:change_note]
  end

  def note
    content_item.details[:change_note]
  end

  def history
    content_item.details[:change_history]
  end
end
