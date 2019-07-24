class AddOrganisationIdToAccessLimit < ActiveRecord::Migration[5.2]
  def change
    add_column :access_limits, :organisations, :json, null: false, default: []
  end
end
