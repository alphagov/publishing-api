class RenameAlternativeUrl < ActiveRecord::Migration
  def change
    rename_column :unpublishings, :alternative_url, :alternative_path
  end
end
