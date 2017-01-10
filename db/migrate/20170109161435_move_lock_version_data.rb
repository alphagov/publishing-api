class MoveLockVersionData < ActiveRecord::Migration[5.0]
  def up
    execute "UPDATE link_sets
             SET lock_version = t.number
             FROM (SELECT target_id, number FROM lock_versions) t
             WHERE link_sets.id = t.target_id"

    execute "UPDATE documents
             SET lock_version = COALESCE(t.max_number, 1)
             FROM (SELECT document_id, MAX(number) AS max_number
                   FROM content_items LEFT JOIN lock_versions
                   ON content_items.id = lock_versions.target_id
                   GROUP BY document_id) t
             WHERE documents.id = t.document_id"
  end

  def down
    execute "UPDATE lock_versions
             SET number = t.lock_version
             FROM (SELECT id, lock_version FROM link_sets) t
             WHERE lock_versions.target_id = t.id"

    execute "UPDATE lock_versions
             SET number = t.lock_version
             FROM (SELECT content_items.id AS id, lock_version
                   FROM content_items LEFT JOIN documents
                   ON documents.id = content_items.document_id) t
             WHERE lock_versions.target_id = t.id"
  end
end
