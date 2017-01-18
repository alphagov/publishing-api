module Presenters
  class ChangeHistoryPresenter
    attr_reader :web_content_item

    def initialize(web_content_item)
      @web_content_item = web_content_item
    end

    def change_history
      details[:change_history] || change_notes_for_content_item
    end

  private

    def details
      SymbolizeJSON.symbolize(web_content_item.details)
    end

    def change_notes_for_content_item
      change_notes = ChangeNote
        .where(content_id: content_id)
        .where("content_item_id IS NULL OR content_item_id IN (?)", content_item_ids)
        .order(:public_timestamp)
        .pluck(:note, :public_timestamp)
        .map { |note, timestamp| { note: note, public_timestamp: timestamp } }
      SymbolizeJSON.symbolize(change_notes.as_json)
    end

    def content_item_ids
      ContentItem.joins(:document)
        .where("documents.content_id": content_id)
        .where("user_facing_version <= ?", version_number)
        .pluck(:id)
    end

    def version_number
      web_content_item.user_facing_version
    end

    def content_id
      web_content_item.content_id
    end
  end
end
