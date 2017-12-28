require "csv"
require_relative "helpers/february29th2016"

class FixShortUrlManagerFirstPublishedAt < ActiveRecord::Migration[5.1]
  def up
    data = CSV.read(
      Rails.root.join(
        "db", "migrate", "data", "short_url_manager_first_published_at.csv"
      )
    )

    Helpers::February29th2016.replace_first_published_at(
      data,
      where_conditions: { publishing_app: "short-url-manager" },
    )

    data = CSV.read(
      Rails.root.join(
        "db", "migrate", "data", "short_url_manager_redirect_created_at.csv"
      )
    )

    Helpers::February29th2016.replace_first_published_at(
      data,
      where_conditions: { publishing_app: "short-url-manager" },
    )
  end
end
