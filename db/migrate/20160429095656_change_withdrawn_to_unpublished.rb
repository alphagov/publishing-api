class ChangeWithdrawnToUnpublished < ActiveRecord::Migration[4.2]
  def up
    create_table :unpublishings do |t|
      t.references :content_item, null: false
      t.string :type, null: false
      t.string :explanation
      t.string :alternative_url
      t.timestamps
    end

    add_index :unpublishings, :content_item_id
    add_index :unpublishings, %i[content_item_id type]
  end

  def down
    drop_table :unpublishings
  end
end
