module Presenters
  class ChangeHistoryPresenter
    attr_reader :edition

    def initialize(edition)
      @edition = edition
    end

    def change_history
      SymbolizeJSON.symbolize(
        change_notes.as_json,
      )
    end

  private

    def change_notes
      query_result.pluck(:note, :public_timestamp)
                  .map { |note, timestamp| { note:, public_timestamp: timestamp } }
    end

    def query_result
      Presenters::Queries::ChangeHistory.new(edition).call
    end
  end
end
