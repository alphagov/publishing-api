class RemoveContentIdsFromChangeNotes < ActiveRecord::Migration[5.1]
  def change
    remove_column :change_notes, :content_id, :string
  end
end
