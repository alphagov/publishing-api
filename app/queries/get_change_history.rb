module Queries
  class GetChangeHistory
    def self.call(publishing_app)
      Queries::GetLatest.
        call(editions(publishing_app)).
        pluck(:id, "details->>'change_history'").
        flat_map do |editions_id, item_history|
          JSON.parse(item_history).map do |item_history_element|
            item_history_element.symbolize_keys.merge(content_item_id: editions_id)
          end
        end
    end

    def self.editions(publishing_app)
      Edition.
        where(publishing_app: publishing_app).
        where("json_array_length(details->'change_history') > 0")
    end
  end
end
