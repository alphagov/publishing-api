require "csv"
require_relative "helpers/february29th2016"

class FixMiscFirstPublishedAt < ActiveRecord::Migration[5.1]
  def up
    data = CSV.read(
      Rails.root.join(
        "db", "migrate", "data", "misc_public_updated_at.csv"
      )
    )

    Helpers::February29th2016.replace_first_published_at(data)
  end
end
