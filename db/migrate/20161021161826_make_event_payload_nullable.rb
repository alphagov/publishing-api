class MakeEventPayloadNullable < ActiveRecord::Migration[5.0]
  def change
    change_column_null(:events, :payload, true)
  end
end
