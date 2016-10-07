module Presenters
  class ChangeHistoryPresenter
    attr_reader :content_item

    def initialize(content_item)
      @content_item = content_item
    end

    def change_history
      content_item.details[:change_history] || change_notes_for_content_item
    end

  private

    def change_notes_for_content_item
      ChangeNote
        .joins(:content_item)
        .where("content_items.content_id" => content_item.content_id)
        .order(public_timestamp: :desc)
        .map { |cn| cn.slice(:note, :public_timestamp) }
    end
  end
end
