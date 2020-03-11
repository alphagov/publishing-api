class ChangeDescriptionColumnTypes < ActiveRecord::Migration[4.2]
  class DraftContentItem < ApplicationRecord
  end

  class LiveContentItem < ApplicationRecord
  end

  def change
    [
      [:draft_content_items, DraftContentItem],
      [:live_content_items, LiveContentItem],
    ].each do |table, model|
      add_column table, :new_description, :json

      # http://www.postgresql.org/docs/9.3/static/functions-json.html#FUNCTIONS-JSON-TABLE
      ActiveRecord::Base.connection.execute(%{
        update #{table} set new_description = concat('{"value":', to_json(description), '}')::json
        where description is not null
      })

      change_column_default table, :new_description, { value: nil }
      model.where(new_description: nil).find_each do |item|
        item.update_column(:new_description, { value: nil }.to_json)
      end

      rename_column table, :description, :old_description
      rename_column table, :new_description, :description
    end
  end
end
