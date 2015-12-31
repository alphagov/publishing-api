class ExtractAccessLimiting < ActiveRecord::Migration
  def up
    create_table :access_limits do |t|
      t.integer :target_id, null: false
      t.string :target_type, null: false
      t.json :users, null: false, default: []
      t.timestamps null: false
    end

    DraftContentItem.where("access_limited::text <> '{}'::text").each do |limited_draft|
      AccessLimit.create(
        target: limited_draft,
        users: limited_draft.access_limited[:users],
      )
    end
  end

  def down
    drop_table :access_limits
  end
end
