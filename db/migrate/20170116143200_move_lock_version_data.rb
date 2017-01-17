class MoveLockVersionData < ActiveRecord::Migration[5.0]
  def up
    execute "UPDATE link_sets
             SET stale_lock_version = t.number
             FROM (SELECT target_id, number FROM lock_versions) t
             WHERE link_sets.id = t.target_id"

    execute "UPDATE documents
             SET stale_lock_version = COALESCE(t.max_number, 1)
             FROM (SELECT document_id, MAX(number) AS max_number
                   FROM content_items LEFT JOIN lock_versions
                   ON content_items.id = lock_versions.target_id
                   GROUP BY document_id) t
             WHERE documents.id = t.document_id"
  end
end
