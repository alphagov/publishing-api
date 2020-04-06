class AddJsonbColumns < ActiveRecord::Migration[5.2]
  def change
    change_table :access_limits, bulk: true do |t|
      t.jsonb :temp_users, :temp_organisations
    end

    change_table :editions, bulk: true do |t|
      t.jsonb :temp_details, :temp_routes, :temp_redirects
    end

    add_column :events, :temp_payload, :jsonb
    add_column :expanded_links, :temp_expanded_links, :jsonb
    add_column :unpublishings, :temp_redirects, :jsonb
  end
end
