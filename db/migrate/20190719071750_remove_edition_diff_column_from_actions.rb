class RemoveEditionDiffColumnFromActions < ActiveRecord::Migration[5.2]
  def change
    remove_column :actions, :edition_diff, :text
  end
end
