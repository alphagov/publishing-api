class Event < ApplicationRecord
  include SymbolizeJSON

  def as_csv
    attributes.merge("payload" => payload.to_json).delete_if { |k, _| k == "temp_payload" }
  end

  def self.maximum_id
    Event.maximum(:id) || 0
  end
end
