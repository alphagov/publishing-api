class UniqueContentStoreForContentIdAndLocale < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def change
    # No 2 content items with the same content_id and locale can be on the
    # same content_store at same time
    add_index :content_items,
              %i[content_id locale content_store],
              unique: true,
              algorithm: :concurrently
  end
end
