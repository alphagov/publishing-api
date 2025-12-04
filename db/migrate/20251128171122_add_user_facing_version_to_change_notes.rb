class AddUserFacingVersionToChangeNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :change_notes, :user_facing_version, :integer
  end
end
