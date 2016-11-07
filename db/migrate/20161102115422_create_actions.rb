class CreateActions < ActiveRecord::Migration[5.0]
  def change
    create_table :actions do |t|
      t.uuid     :content_id, null: false
      t.string   :locale
      t.string   :action, null: false
      t.uuid     :user_uid
      t.references :content_item, index: true, foreign_key: false, null: true
      t.references :link_set, index: true, foreign_key: false, null: true
      t.references :event, index: true, foreign_key: false, null: false
      t.timestamps
    end
  end
end
