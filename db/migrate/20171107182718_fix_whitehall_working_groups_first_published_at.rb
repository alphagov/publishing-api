require "csv"
require_relative "helpers/february29th2016"

class FixWhitehallWorkingGroupsFirstPublishedAt < ActiveRecord::Migration[5.1]
  def up
    data = CSV.read(
      Rails.root.join(
        "db", "migrate", "data", "whitehall_working_groups_first_published_at.csv"
      )
    )

    Helpers::February29th2016.replace_first_published_at(
      data,
      where_conditions: { publishing_app: "whitehall" },
    )
  end
end
