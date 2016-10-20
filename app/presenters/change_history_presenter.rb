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
        .joins(:content_item)
        .where("content_items.content_id" => content_item.content_id)
        .joins("INNER JOIN user_facing_versions ON user_facing_versions.content_item_id = content_items.id")
        .where("user_facing_versions.number <= ?", version_number)
        .order(public_timestamp: :desc)
        .pluck(:note, :public_timestamp)
        .map do |note, timestamp|
          { note: note, public_timestamp: timestamp }.stringify_keys
        end
    end

    def version_number
      UserFacingVersion.where(content_item_id: content_item.id).last.number
    end
  end
end
