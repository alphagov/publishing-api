class ChangeNote < ActiveRecord::Base
  belongs_to :edition

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
    ChangeNote
      .find_or_create_by!(edition: edition)
      .update!(
        note: change_note,
        content_id: edition.document.content_id,
        public_timestamp: Time.zone.now
      )
  end

  def create_from_details_hash_change_note
    return unless note
    ChangeNote
      .find_or_create_by!(edition: edition)
      .update!(
        content_id: edition.document.content_id,
        public_timestamp: edition.updated_at,
        note: note,
      )
  end

  def create_from_details_hash_change_history
    return unless change_history.present?
    history_element = change_history.max_by { |h| h[:public_timestamp] }
    ChangeNote
      .find_or_create_by!(edition: edition)
      .update!(
        history_element.merge(content_id: edition.document.content_id)
      )
  end

  def update_type
    @update_type ||= payload[:update_type] || edition.update_type
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
