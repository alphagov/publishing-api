class CreateFriendlyIds < ActiveRecord::Migration[7.2]
  def change
    create_table :friendly_ids do |t|
      t.string :friendly_id, null: false, index: true
      t.string :content_id, null: false, index: true

      t.timestamps null: false
    end
  end
end
