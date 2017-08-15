class MakePositionRequired < ActiveRecord::Migration[4.2]
  def change
    change_column :links, :position, :integer, null: false, default: 0
  end
end
