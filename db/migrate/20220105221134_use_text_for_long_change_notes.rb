class UseTextForLongChangeNotes < ActiveRecord::Migration[6.1]
  def up
    change_column :change_notes, :note, :text
  end

  def down
    change_column :change_notes, :note, :string
  end
end
