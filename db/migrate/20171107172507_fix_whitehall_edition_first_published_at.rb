require "csv"
require_relative "helpers/february29th2016"

class FixWhitehallEditionFirstPublishedAt < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    data = CSV.read(
      Rails.root.join(
        "db", "migrate", "data", "whitehall_editions_first_published_at.csv"
      )
    )

    Helpers::February29th2016.replace_first_published_at(
      data,
      first_published_at_position: 2,
      where_conditions: { publishing_app: "whitehall" },
    )
  end
end
