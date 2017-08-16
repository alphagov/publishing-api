class MakeChangesNotesEditionIdNotNullable < ActiveRecord::Migration[5.1]
  def change
    change_column_null :change_notes, :edition_id, false
  end
end
