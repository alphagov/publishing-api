class Event < ApplicationRecord
  include SymbolizeJSON

  before_save :save_to_temp_columns

  def as_csv
    attributes.merge("payload" => payload.to_json)
  end

  def self.maximum_id
    Event.maximum(:id) || 0
  end

  def save_to_temp_columns
    self.temp_payload = payload
  end
end
