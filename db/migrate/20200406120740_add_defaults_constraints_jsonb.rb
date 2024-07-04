class AddDefaultsConstraintsJsonb < ActiveRecord::Migration[5.2]
  def change
    # Add defaults and constraints to new jsonb columns
    change_table :access_limits, bulk: true do |t|
      t.change_default :temp_users, from: nil, to: []
      t.change_default :temp_organisations, from: nil, to: []
    end

    change_column_null :access_limits, :temp_users, false # rubocop:disable Rails/BulkChangeTable
    change_column_null :access_limits, :temp_organisations, false

    change_table :editions, bulk: true do |t|
      t.change_default :temp_details, from: nil, to: {}
      t.change_default :temp_routes, from: nil, to: []
      t.change_default :temp_redirects, from: nil, to: []
    end

    change_column_default(:events, :temp_payload, from: nil, to: {})

    change_column_default(:expanded_links, :temp_expanded_links, from: nil, to: {}) # rubocop:disable Rails/BulkChangeTable
    change_column_null :expanded_links, :temp_expanded_links, false, {}
  end
end
