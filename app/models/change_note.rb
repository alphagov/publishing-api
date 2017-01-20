class ChangeNote < ActiveRecord::Base
  belongs_to :edition, foreign_key: "content_item_id"

  def self.create_from_edition(payload, edition)
    ChangeNoteFactory.new(payload, edition).build
  end

  def self.join_editions(edition_scope)
    edition_scope.joins(
      "LEFT JOIN change_notes ON change_notes.content_item_id = content_items.id"
    )
  end
end

class ChangeNoteFactory
  def initialize(payload, edition)
    @payload = payload
    @edition = edition
  end

  def build
    return unless edition.update_type == "major"
    create_from_top_level_change_note ||
      create_from_details_hash_change_note ||
      create_from_details_hash_change_history
  end

private

  attr_reader :payload, :edition

  def create_from_top_level_change_note
    return unless change_note
    ChangeNote.
      find_or_create_by!(edition: edition).
      update!(
        note: change_note,
        content_id: edition.content_id,
        public_timestamp: Time.zone.now
      )
  end

  def create_from_details_hash_change_note
    return unless note
    ChangeNote.create!(
      edition: edition,
      content_id: edition.content_id,
      public_timestamp: edition.updated_at,
      note: note,
    )
  end

  def create_from_details_hash_change_history
    return unless change_history.present?
    history_element = change_history.max_by { |h| h[:public_timestamp] }
    ChangeNote.create!(
      history_element.merge(
        edition: edition,
        content_id: edition.content_id
      )
    )
  end

  def change_note
    payload[:change_note]
  end

  def note
    edition.details[:change_note]
  end

  def change_history
    edition.details[:change_history]
  end
end
