module Presenters
  class ChangeHistoryPresenter
    attr_reader :edition

    def initialize(edition)
      @edition = edition
    end

    def change_history
      details[:change_history] ? merged_change_notes : presented_change_notes
    end

  private

    def merged_change_notes
      SymbolizeJSON.symbolize(
        details[:change_history].concat(
          change_notes(include_root_changes: false),
        ).sort_by { |v| v[:public_timestamp] }.reverse.as_json,
      )
    end

    def details
      @details ||= SymbolizeJSON.symbolize(edition.details)
    end

    def presented_change_notes
      SymbolizeJSON.symbolize(
        change_notes.as_json,
      )
    end

    def change_notes(include_root_changes: true)
      query_result(include_root_changes:).pluck(:note, :public_timestamp)
                  .map { |note, timestamp| { note:, public_timestamp: timestamp } }
    end

    def query_result(include_root_changes: true)
      Presenters::Queries::ChangeHistory.new(edition, include_root_changes:).call
    end
  end
end
