class ChangeNote < ActiveRecord::Base
  belongs_to :edition, optional: true

  def self.create_from_edition(payload, edition)
    ChangeNoteFactory.new(payload, edition).build
  end
end

class ChangeNoteFactory
  def initialize(payload, edition)
    @payload = payload
    @edition = edition
  end

  def build
    return unless update_type == "major"

    create_from_top_level_change_note ||
      create_from_details_hash_change_note ||
      create_from_details_hash_change_history
  end

private

  attr_reader :payload, :edition

  def create_from_top_level_change_note
    return unless change_note

    change_note_instance.update!(
      public_timestamp: payload[:public_updated_at] || Time.zone.now,
      note: change_note,
    )
  end

  def create_from_details_hash_change_note
    return unless note

    change_note_instance.update!(
      public_timestamp: edition.public_updated_at,
      note: note,
    )
  end

  def create_from_details_hash_change_history
    return unless change_history.present?

    history_element = change_history.max_by { |h| h[:public_timestamp] }
    change_note_instance.update!(
      public_timestamp: history_element.fetch(:public_timestamp),
      note: history_element.fetch(:note),
    )
  end

  def update_type
    @update_type ||= payload[:update_type] || edition.update_type
  end

  def change_note_instance
    edition.change_note || edition.create_change_note!
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
