class CreateContentIdAliases < ActiveRecord::Migration[7.2]
  def change
    create_table :content_id_aliases do |t|
      t.string :name, null: false
      t.uuid :content_id, null: false, index: true

      t.timestamps
    end

    add_index :content_id_aliases, :name, unique: true
  end
end
