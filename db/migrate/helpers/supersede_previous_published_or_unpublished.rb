module Helpers
  module SupersedePreviousPublishedOrUnpublished
    def self.run
      state_histories = ContentItem
        .where(state: %w(published unpublished))
        .group(:content_id, :locale)
        .having("count(content_id) > 1")
        .pluck("json_agg((id, user_facing_version))")
        .map do |results|
          results.map { |row| { content_item_id: row["f1"], version: row["f2"] } }
        end

      content_items_to_supersede = state_histories.flat_map do |history|
        newest = history.max_by { |r| r[:version] }

        history.delete(newest)
        history.map { |r| r[:content_item_id] }
      end

      ContentItem.where(id: content_items_to_supersede).update_all(state: "superseded")

      content_items_to_supersede.count
    end
  end
end
