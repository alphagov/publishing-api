class ExtractAccessLimiting < ActiveRecord::Migration[4.2]
  class DraftContentItem < ApplicationRecord
  end

  def up
    create_table :access_limits do |t|
      t.integer :target_id, null: false
      t.string :target_type, null: false
      t.json :users, null: false, default: []
      t.timestamps null: false
    end

    add_index :access_limits, %i[target_type target_id], name: "index_access_limits_on_target"

    DraftContentItem.where("access_limited::text <> '{}'::text").each do |limited_draft|
      users = limited_draft.access_limited[:users]

      AccessLimit.create!(
        target: limited_draft,
        users: users,
      )

      puts "AccessLimit created for #{limited_draft.content_id} (#{users.size} users)"
    end
  end

  def down
    remove_index :access_limits, name: "index_access_limits_on_target"
    drop_table :access_limits
  end
end
