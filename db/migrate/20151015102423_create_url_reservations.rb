class CreateUrlReservations < ActiveRecord::Migration
  def change
    create_table :url_reservations do |t|
      t.string :path, :null => false
      t.string :publishing_app, :null => false

      t.timestamps
    end

    add_index :url_reservations, :path, :unique => true
  end
end
