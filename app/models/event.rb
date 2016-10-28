class Event < ApplicationRecord
  include SymbolizeJSON

  def as_csv
    attributes.merge("payload" => payload.to_json)
  end
end
