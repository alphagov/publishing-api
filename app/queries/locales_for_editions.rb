module Queries
  module LocalesForEditions
    # returns an array of form:
    # [
    #   [content_id, locale],
    #   [content_id, locale],
    # ]
    def self.call(
      content_ids,
      content_stores = %w[draft live]
    )
      Document.joins(:editions)
        .where(
          content_id: content_ids,
          editions: { content_store: content_stores },
        )
        .distinct
        .order(:content_id, :locale)
        .pluck(:content_id, :locale)
    end
  end
end
