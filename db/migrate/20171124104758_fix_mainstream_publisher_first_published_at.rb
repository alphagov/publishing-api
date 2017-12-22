require "csv"
require_relative "helpers/february29th2016"

class FixMainstreamPublisherFirstPublishedAt < ActiveRecord::Migration[5.1]
  def up
    data = CSV.read(
      Rails.root.join(
        "db", "migrate", "data", "mainstream-publisher-first-published-at.csv"
      )
    )

    Helpers::February29th2016.replace_first_published_at(
      data,
      where_conditions: { publishing_app: "publisher" },
    )
  end
end
