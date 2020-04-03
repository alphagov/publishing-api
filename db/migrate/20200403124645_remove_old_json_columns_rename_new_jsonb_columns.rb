class RemoveOldJsonColumnsRenameNewJsonbColumns < ActiveRecord::Migration[5.2]
  def up
    # Remove json columns
    change_table :access_limits, bulk: true do |t|
      t.remove :users, :organisations
    end

    change_table :editions, bulk: true do |t|
      t.remove :details, :routes, :redirects
    end

    remove_column :events, :payload, :json
    remove_column :expanded_links, :expanded_links, :json
    remove_column :unpublishings, :redirects, :json
  end

  def down; end

  def change
    # Add defaults and constraints to new jsonb columns
    change_table :access_limits, bulk: true do |t|
      t.change_default :temp_users, from: nil, to: []
      t.change_default :temp_organisations, from: nil, to: []
    end

    change_column_null :access_limits, :temp_users, false
    change_column_null :access_limits, :temp_organisations, false

    change_table :editions, bulk: true do |t|
      t.change_default :temp_details, from: nil, to: {}
      t.change_default :temp_routes, from: nil, to: []
      t.change_default :temp_redirects, from: nil, to: []
    end

    change_column_default(:events, :temp_payload, from: nil, to: {})

    change_column_default(:expanded_links, :temp_expanded_links, from: nil, to: {})
    change_column_null :expanded_links, :temp_expanded_links, false, {}

    # Rename new jsonb columns
    change_table :access_limits, bulk: true do |t|
      t.rename :temp_users, :users
      t.rename :temp_organisations, :organisations
    end

    change_table :editions, bulk: true do |t|
      t.rename :temp_details, :details
      t.rename :temp_routes, :routes
      t.rename :temp_redirects, :redirects
    end

    rename_column :events, :temp_payload, :payload
    rename_column :expanded_links, :temp_expanded_links, :expanded_links
    rename_column :unpublishings, :temp_redirects, :redirects
  end
end
