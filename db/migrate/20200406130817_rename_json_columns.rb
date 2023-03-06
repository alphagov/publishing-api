class RenameJSONColumns < ActiveRecord::Migration[5.2]
  def change
    change_table :access_limits, bulk: true do |t|
      t.rename :users, :old_users
      t.rename :organisations, :old_organisations
      t.rename :temp_users, :users
      t.rename :temp_organisations, :organisations
      t.rename :old_users, :temp_users
      t.rename :old_organisations, :temp_organisations
    end

    change_table :editions, bulk: true do |t|
      t.rename :details, :old_details
      t.rename :routes, :old_routes
      t.rename :redirects, :old_redirects
      t.rename :temp_details, :details
      t.rename :temp_routes, :routes
      t.rename :temp_redirects, :redirects
      t.rename :old_details, :temp_details
      t.rename :old_routes, :temp_routes
      t.rename :old_redirects, :temp_redirects
    end

    change_table :events, bulk: true do |t|
      t.rename :payload, :old_payload
      t.rename :temp_payload, :payload
      t.rename :old_payload, :temp_payload
    end

    change_table :expanded_links, bulk: true do |t|
      t.rename :expanded_links, :old_expanded_links
      t.rename :temp_expanded_links, :expanded_links
      t.rename :old_expanded_links, :temp_expanded_links
    end

    change_table :unpublishings, bulk: true do |t|
      t.rename :redirects, :old_redirects
      t.rename :temp_redirects, :redirects
      t.rename :old_redirects, :temp_redirects
    end
  end
end
