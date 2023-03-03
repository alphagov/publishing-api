class RemoveJSONColumns < ActiveRecord::Migration[6.0]
  def up
    change_table :access_limits, bulk: true do |t|
      t.remove :temp_users, :temp_organisations
    end

    change_table :editions, bulk: true do |t|
      t.remove :temp_details, :temp_routes, :temp_redirects
    end

    remove_column :events, :temp_payload, :json
    remove_column :expanded_links, :temp_expanded_links, :json
    remove_column :unpublishings, :temp_redirects, :json
  end

  def down; end
end
