module SchemaGenerator
  # This class adds change history as part of the details hash as this is
  # something done automatically by Publishing API and should be changed there
  # to be outside the details hash
  class ApplyChangeHistoryDefinitions
    def self.call(definitions)
      return definitions unless definitions["details"]

      definitions.tap do |d|
        if d["details"]["oneOf"]
          d["details"]["oneOf"].each do |details|
            add_change_history(details)
          end
        else
          add_change_history(d["details"])
        end
      end
    end

    def self.add_change_history(hash)
      hash["properties"]["change_history"] = {
        "$ref" => "#/definitions/change_history",
      }
    end
  end
end
