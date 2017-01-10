class MoveLockVersionData < ActiveRecord::Migration[5.0]
  def up
    execute "UPDATE link_sets
             SET lock_version = t.number
             FROM (SELECT target_id, number FROM lock_versions) t
             WHERE link_sets.id = t.target_id"
  end

  def down
    execute "UPDATE lock_versions
             SET number = t.lock_version
             FROM (SELECT id, lock_version FROM link_sets) t
             WHERE lock_versions.target_id = t.id"
  end
end
