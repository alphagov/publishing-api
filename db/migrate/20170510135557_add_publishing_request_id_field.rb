class AddPublishingRequestIdField < ActiveRecord::Migration[5.0]
  def change
    add_column :editions, :publishing_request_id, :string
  end
end
