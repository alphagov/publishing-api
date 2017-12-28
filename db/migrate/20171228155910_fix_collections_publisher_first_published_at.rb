require "csv"
require_relative "helpers/february29th2016"

class FixCollectionsPublisherFirstPublishedAt < ActiveRecord::Migration[5.1]
  def up
    data = CSV.read(
      Rails.root.join(
        "db", "migrate", "data", "collections_publisher_first_published_at.csv"
      )
    )

    Helpers::February29th2016.replace_first_published_at(
      data,
      where_conditions: { publishing_app: "collections-publisher" },
    )
  end
end
