class AddContentIdToEvent < ActiveRecord::Migration
  def up
    add_column :events, :content_id, :string

    ActiveRecord::Base.connection.execute("
      UPDATE events
      SET content_id = payload->>'content_id'
    ")

    add_index :events, :content_id
  end

  def down
    remove_column :events, :content_id
    remove_index :events, :content_id
  end
end
