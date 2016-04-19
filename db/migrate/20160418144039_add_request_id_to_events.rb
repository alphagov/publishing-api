class AddRequestIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :request_id, :string
  end
end
