class AddIndexForCmsEntityIds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # add_index :editions, %i[cms_entity_ids updated_at id], using: "gin", algorithm: :concurrently
    # add_index :editions, :cms_entity_ids, using: "gin", algorithm: :concurrently
    # add_index :editions, %i[cms_entity_ids updated_at id state], using: "gin", algorithm: :concurrently, name: "arggh"
    add_index :editions, %i[cms_entity_ids updated_at id state], using: "gin", algorithm: :concurrently, name: "a_test"
    add_index :editions, %i[cms_entity_ids updated_at id], using: "gin", where: "state in ('draft', 'published', 'unpublished')", algorithm: :concurrently, name: "another_test"
    # add_index :editions, %i[updated_at id], where: "state in ('draft', 'published', 'unpublished')", algorithm: :concurrently, name: "testy_test", order: { updated_at: :asc, id: :asc }
    # add_index :editions, %i[updated_at id], where: "state in ('draft', 'published', 'unpublished')", algorithm: :concurrently, name: "testy_test_2", order: { updated_at: :desc, id: :desc }
  end
end
