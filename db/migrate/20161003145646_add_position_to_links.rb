class AddPositionToLinks < ActiveRecord::Migration[4.2]
  def change
    add_column :links, :position, :integer
  end
end
