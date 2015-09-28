class AddDerivedRepresentations < ActiveRecord::Migration
  def change
    create_table :draft_content_items do |t|
      t.string :content_id
      t.string :locale
      t.integer :version, null: false

      t.string :base_path
      t.string :title
      t.string :description
      t.string :format
      t.datetime :public_updated_at

      t.json :access_limited
      t.json :metadata
      t.json :details
      t.json :routes
      t.json :redirects
      t.string :publishing_app
      t.string :rendering_app
    end
    add_index :draft_content_items, [:content_id, :locale], unique: true

    create_table :live_content_items do |t|
      t.string :content_id
      t.string :locale
      t.integer :version, null: false

      t.string :base_path
      t.string :title
      t.string :description
      t.string :format
      t.datetime :public_updated_at

      t.json :metadata
      t.json :details
      t.json :routes
      t.json :redirects
      t.string :publishing_app
      t.string :rendering_app
    end
    add_index :live_content_items, [:content_id, :locale], unique: true

    create_table :link_sets do |t|
      t.string :content_id
      t.integer :version, null: false

      t.json :links
    end
    add_index(:link_sets, :content_id, unique: true)
  end
end
