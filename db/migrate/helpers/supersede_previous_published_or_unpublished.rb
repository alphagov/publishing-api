module Helpers
  module SupersedePreviousPublishedOrUnpublished
    def self.run
      state_histories = State
        .where(name: %w(published unpublished))
        .joins(:content_item)
        .joins("INNER JOIN translations t on t.content_item_id = content_items.id")
        .joins("INNER JOIN user_facing_versions u on u.content_item_id = content_items.id")
        .group(:content_id, 't.locale')
        .having("count(content_id) > 1")
        .pluck("json_agg((states.id, u.number))")
        .map do |results|
          results.map { |row| { state_id: row["f1"], version: row["f2"] } }
        end

      states_to_supersede = state_histories.flat_map do |history|
        newest = history.max_by { |r| r[:version] }

        history.delete(newest)
        history.map { |r| r[:state_id] }
      end

      State.where(id: states_to_supersede).update_all(name: "superseded")

      states_to_supersede.count
    end
  end
end
