class RemoveContentIdAndLocaleColumns < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    remove_column :content_items, :content_id
    remove_column :content_items, :locale
  end

  def down
    add_column :content_items, :content_id, :uuid
    add_column :content_items, :locale, :string

    add_index :content_items,
      [:content_id, :locale, :user_facing_version],
      unique: true,
      algorithm: :concurrently,
      name: "index_unique_ufv_content_id_locale"

    add_index :content_items,
      [:content_id, :locale, :content_store],
      unique: true,
      algorithm: :concurrently

    add_index :content_items, :content_id, algorithm: :concurrently

    add_index :content_items,
      [:content_id, :state, :locale],
      algorithm: :concurrently
  end
end
