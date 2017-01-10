module Helpers
  module SupersedePreviousPublishedOrUnpublished
    def self.run
      state_histories = Edition
        .joins(:document)
        .where(state: %w(published unpublished))
        .group("documents.content_id", :locale)
        .having("count(documents.content_id) > 1")
        .pluck("json_agg((editions.id, user_facing_version))")
        .map do |results|
          results.map { |row| { edition_id: row["f1"], version: row["f2"] } }
        end

      editions_to_supersede = state_histories.flat_map do |history|
        newest = history.max_by { |r| r[:version] }

        history.delete(newest)
        history.map { |r| r[:content_item_id] }
      end

      Edition.where(id: content_items_to_supersede).update_all(state: "superseded")

      editions_to_supersede.count
    end
  end
end
