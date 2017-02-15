module Presenters
  class ChangeHistoryPresenter
    attr_reader :edition

    def initialize(edition)
      @edition = edition
    end

    def change_history
      details[:change_history] || change_notes_for_content_item
    end

  private

    def details
      SymbolizeJSON.symbolize(edition.details)
    end

    def change_notes_for_content_item
      change_notes = ChangeNote
        .where(content_id: content_id)
        .where("edition_id IS NULL OR edition_id IN (?)", edition_ids)
        .order(:public_timestamp)
        .pluck(:note, :public_timestamp)
        .map { |note, timestamp| { note: note, public_timestamp: timestamp } }
      SymbolizeJSON.symbolize(change_notes.as_json)
    end

    def edition_ids
      Edition.with_document
        .where("documents.content_id": content_id)
        .where("user_facing_version <= ?", version_number)
        .pluck(:id)
    end

    def version_number
      edition.user_facing_version
    end

    def content_id
      edition.content_id
    end
  end
end
