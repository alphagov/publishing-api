class ChangeDescriptionColumnTypes < ActiveRecord::Migration
  def change
    [
      [:draft_content_items, DraftContentItem],
      [:live_content_items, LiveContentItem],
    ].each do |table, model|
      add_column table, :new_description, :json

      # http://www.postgresql.org/docs/9.3/static/functions-json.html#FUNCTIONS-JSON-TABLE
      ActiveRecord::Base.connection.execute("update #{table} set new_description = to_json(description)")

      rename_column table, :description, :old_description
      rename_column table, :new_description, :description
    end
  end
end
