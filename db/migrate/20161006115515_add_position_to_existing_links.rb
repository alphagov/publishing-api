class AddPositionToExistingLinks < ActiveRecord::Migration[4.2]
  def change
    Link.where(position: nil).update_all(position: 0)
  end
end
