class CreateVersions < ActiveRecord::Migration[4.2]
  def change
    create_table :versions do |t|
      t.integer :target_id, null: false
      t.string :target_type, null: false
      t.integer :number, null: false, default: 0
      t.timestamps null: false
    end
  end
end
