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
      all_change_notes
        .map { |h| format_change_note(h) }
        .sort_by { |h| Time.zone.parse(h[:public_timestamp]) }
        .reverse
    end

    def format_change_note(history)
      {
        note: history[:note],
        public_timestamp: convert_timestamp_to_utc(history[:public_timestamp]).iso8601,
      }
    end

    def all_change_notes
      query_result + details_change_notes
    end

    def details_change_notes
      @details_change_notes ||= edition.details.fetch(:change_history, [])
    end

    def query_result
      Presenters::Queries::ChangeHistory.new(edition, include_edition_change_history: details_change_notes.blank?)
                                        .call
                                        .pluck(:note, :public_timestamp)
                                        .map { |note, timestamp| { note:, public_timestamp: timestamp } }
    end

    def convert_timestamp_to_utc(timestamp)
      timestamp.is_a?(String) ? Time.zone.parse(timestamp).utc : timestamp.utc
    end
  end
end
