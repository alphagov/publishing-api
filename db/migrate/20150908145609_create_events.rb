class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string   "action", null: false
      t.json     "payload", null: false
      t.string   "user_uid"
      t.timestamps
    end
  end
end
