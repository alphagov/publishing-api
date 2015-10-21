class CreateUrlReservations < ActiveRecord::Migration
  def change
    create_table :url_reservations do |t|
      t.string :base_path, :null => false
      t.string :publishing_app, :null => false

      t.timestamps
    end

    add_index :url_reservations, :base_path, :unique => true
  end
end
