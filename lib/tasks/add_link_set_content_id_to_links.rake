desc "Add link_set_content_id to links"
task :add_link_set_content_id_to_links, [:link_id] => [:environment] do |t, args|
  link_id = args.fetch(:link_id, 0).to_i
  link_set_links = Link.joins(:link_set).includes(:link_set).where(id: link_id..)
  count = 0
  total = link_set_links.count

  link_set_links.find_in_batches do |links|
    puts "Processing link ids from #{links.first.id} to #{links.last.id}"
    Link.transaction do
      links.each do |link|
        link.update!(link_set_content_id: link.link_set.content_id)
      end
    end
    count += links.size
    puts "Processed #{(100 * count.to_f / total).round(1)}% (#{count} / #{total})"
    sleep(0.1)
  end
end
