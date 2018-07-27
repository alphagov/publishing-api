class DropUnusedIndexes < ActiveRecord::Migration[5.1]
  def up
    remove_index :actions, name: :index_actions_on_edition_id
    remove_index :actions, name: :index_actions_on_event_id
    remove_index :actions, name: :index_actions_on_link_set_id
    remove_index :editions, name: :index_editions_on_created_at_and_id
    remove_index :editions, name: :index_editions_on_last_edited_at
    remove_index :editions, name: :index_editions_on_public_updated_at
    remove_index :editions, name: :index_editions_on_public_updated_at_and_id
    remove_index :editions, name: :index_editions_on_rendering_app
    remove_index :events, name: :index_events_on_content_id
    remove_index :link_changes, name: :index_link_changes_on_action_id
  end
end
