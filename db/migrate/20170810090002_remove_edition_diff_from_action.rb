class RemoveEditionDiffFromAction < ActiveRecord::Migration[5.1]
  def change
    remove_column :actions, :edition_diff, :text
  end
end
