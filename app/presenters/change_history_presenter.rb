module Presenters
  class ChangeHistoryPresenter
    attr_reader :edition

    def initialize(edition)
      @edition = edition
    end

    def change_history
      details[:change_history] || presented_change_notes
    end

  private

    def details
      SymbolizeJSON.symbolize(edition.details)
    end

    def presented_change_notes
      SymbolizeJSON.symbolize(
        change_notes
          .pluck(:note, :public_timestamp)
          .map { |note, timestamp| { note: note, public_timestamp: timestamp } }
          .as_json,
      )
    end

    def change_notes
      ChangeNote
        .joins(:edition)
        .where(editions: { document: document })
        .where("user_facing_version <= ?", version_number)
        .order(:public_timestamp)
    end

    def version_number
      edition.user_facing_version
    end

    def document
      edition.document
    end
  end
end
