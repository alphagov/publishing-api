class CreateExpandedLinks < ActiveRecord::Migration[5.1]
  def change
    create_table :expanded_links do |t|
      t.uuid :content_id, null: false
      t.string :locale, null: false
      t.boolean :with_drafts, null: false
      t.json :expanded_links, null: false, default: {}
      t.bigint :payload_version, null: false, default: 0
      t.timestamps

      t.index %i[content_id locale with_drafts],
              unique: true,
              name: "expanded_links_content_id_locale_with_drafts_index"
    end
  end
end
