class MakePositionRequired < ActiveRecord::Migration
  def change
    change_column :links, :position, :integer, null: false, default: 0
  end
end
