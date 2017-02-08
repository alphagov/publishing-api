class AddFactCheckIds < ActiveRecord::Migration[5.0]
  def change
    add_column :access_limits, :fact_check_ids, :json, null: false, default: []
  end
end
