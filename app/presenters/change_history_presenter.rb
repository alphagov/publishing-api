module Presenters
  class ChangeHistoryPresenter
    attr_reader :content_item

    def initialize(content_item)
      @content_item = content_item
    end

    def change_history
      details[:change_history] || change_notes_for_content_item
    end

  private

    def details
      SymbolizeJSON.symbolize(content_item.details)
    end

    def change_notes_for_content_item
      ChangeNote
        .where(content_id: content_item.content_id)
        .where("content_item_id IS NULL OR content_item_id IN (?)", content_item_ids)
        .order(:public_timestamp)
        .pluck(:note, :public_timestamp)
        .map do |note, timestamp|
          { note: note, public_timestamp: timestamp }.stringify_keys
        end
    end

    def content_item_ids
      ContentItem.joins(:document)
                 .where('documents.content_id': content_item.content_id)
                 .where("user_facing_version <= ?", version_number)
                 .pluck(:id)
    end

    def version_number
      content_item.user_facing_version
    end
  end
end
