class AddLastEditedByEditorIdToEditions < ActiveRecord::Migration[7.2]
  def change
    add_column :editions, :last_edited_by_editor_id, :uuid
  end
end
