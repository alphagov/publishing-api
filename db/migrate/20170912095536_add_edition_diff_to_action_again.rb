class AddEditionDiffToActionAgain < ActiveRecord::Migration[5.1]
  def change
    add_column :actions, :edition_diff, :text
  end
end
