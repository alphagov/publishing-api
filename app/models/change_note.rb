class ChangeNote < ActiveRecord::Base
  belongs_to :edition, foreign_key: "content_item_id"

  def self.create_from_content_item(payload, content_item)
    ChangeNoteFactory.new(payload, content_item).build
  end

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "LEFT JOIN change_notes ON change_notes.content_item_id = content_items.id"
    )
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
    ChangeNote.
      find_or_create_by!(edition: content_item).
      update!(
        note: change_note,
        content_id: content_item.content_id,
        public_timestamp: Time.zone.now
      )
  end

  def create_from_details_hash_change_note
    return unless note
    ChangeNote.create!(
      edition: content_item,
      content_id: content_item.content_id,
      public_timestamp: content_item.updated_at,
      note: note,
    )
  end

  def create_from_details_hash_change_history
    return unless change_history.present?
    history_element = change_history.max_by { |h| h[:public_timestamp] }
    ChangeNote.create!(
      history_element.merge(
        edition: content_item,
        content_id: content_item.content_id
      )
    )
  end

  def change_note
    payload[:change_note]
  end

  def note
    content_item.details[:change_note]
  end

  def change_history
    content_item.details[:change_history]
  end
end
