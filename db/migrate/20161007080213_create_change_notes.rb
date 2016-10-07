class CreateChangeNotes < ActiveRecord::Migration
  def change
    create_table :change_notes do |t|
      t.string :note, default: ""
      t.datetime :public_timestamp
      t.references :content_item, index: true, foreign_key: true
      t.timestamps
    end
  end
end
