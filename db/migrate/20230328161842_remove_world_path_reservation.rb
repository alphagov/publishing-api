class RemoveWorldPathReservation < ActiveRecord::Migration[7.0]
  def up
    PathReservation.find_by(base_path: "/world")&.delete
  end
end
