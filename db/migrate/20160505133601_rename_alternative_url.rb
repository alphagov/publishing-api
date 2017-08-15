class RenameAlternativeUrl < ActiveRecord::Migration[4.2]
  def change
    rename_column :unpublishings, :alternative_url, :alternative_path
  end
end
