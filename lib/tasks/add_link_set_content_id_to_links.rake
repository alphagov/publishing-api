desc "Add link_set_content_id to links"
task :add_link_set_content_id_to_links, [:link_id] => [:environment] do |_t, args|
  batch_size = 1000
  link_id = args.fetch(:link_id, 0).to_i
  total_updated = 0
  link_set_links = Link.where.not(link_set_id: nil)
  total_count = link_set_links.where(id: link_id...).count

  loop do
    max_link_id = link_set_links.where(id: link_id...)
                                .order(id: :asc).limit(batch_size)
                                .pluck(:id).last
    break if max_link_id.nil?

    puts "Processing link ids from #{link_id} to #{max_link_id}"

    sql = <<-SQL
      UPDATE links
      SET link_set_content_id = link_sets.content_id
      FROM link_sets
      WHERE links.link_set_id IS NOT NULL AND links.link_set_id = link_sets.id
      AND links.id BETWEEN ? AND ?
    SQL

    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([sql, link_id, max_link_id]),
    )

    link_id = max_link_id + 1
    total_updated += batch_size
    puts "Processed #{total_updated} of #{total_count} links so far (#{(total_updated.to_f / total_count * 100).round(1)}%)"
    sleep(0.1)
  end

  puts "Finished processing links. Total updated: #{total_updated}"
end
