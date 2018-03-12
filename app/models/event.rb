class Event < ApplicationRecord
  include SymbolizeJSON

  def as_csv
    attributes.merge("payload" => payload.to_json)
  end

  def self.payload_version(content_id)
    Event.where(content_id: content_id).maximum(:id) || 0
  end
end
