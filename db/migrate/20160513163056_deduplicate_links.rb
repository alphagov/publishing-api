class DeduplicateLinks < ActiveRecord::Migration[4.2]
  def up
    res = Link.connection.execute(<<-SQL,
      SELECT SUM(cnt), COUNT(cnt)
      FROM (
        SELECT
          link_set_id,
          target_content_id,
          link_type,
          COUNT(id) cnt
        FROM links
        WHERE target_content_id IS NOT NULL
        GROUP BY 1,2,3
        HAVING COUNT(id) > 1
      ) sub
      SQL
    )
    puts "#{res[0]["count"]} unique records of #{res[0]["sum"]} total duplicated"

    res = Link.connection.execute(<<-SQL,
      DELETE FROM links USING links l2
        WHERE links.link_set_id = l2.link_set_id
        AND links.target_content_id = l2.target_content_id
        AND links.link_type = l2.link_type
        AND links.id < l2.id
      SQL
    )
    puts "#{res.cmd_tuples} records deleted"
  end
end
