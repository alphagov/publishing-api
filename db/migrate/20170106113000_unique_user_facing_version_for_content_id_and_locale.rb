class UniqueUserFacingVersionForContentIdAndLocale < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def change
    # No 2 content items with the same content_id and locale can share a
    # user_facing_version
    add_index :content_items,
              %i[content_id locale user_facing_version],
              unique: true,
              algorithm: :concurrently,
              name: "index_unique_ufv_content_id_locale"
  end
end
