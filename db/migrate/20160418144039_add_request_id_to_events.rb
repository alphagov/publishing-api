class AddRequestIdToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :request_id, :string
  end
end
