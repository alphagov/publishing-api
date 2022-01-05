class UseTextForLongPathReservations < ActiveRecord::Migration[6.1]
  def up
    change_column :path_reservations, :base_path, :text
  end

  def down
    change_column :path_reservations, :base_path, :string
  end
end
