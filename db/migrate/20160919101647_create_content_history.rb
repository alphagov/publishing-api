class CreateContentHistory < ActiveRecord::Migration
  def change
    create_table :content_histories do |t|
      t.json      "diff", null: false
      t.string    "content_id", null: false
      t.integer   "version", null: false
      t.integer   "previous_version", null: false
      t.timestamps
    end
    add_index :content_histories, [:content_id]
  end
end
