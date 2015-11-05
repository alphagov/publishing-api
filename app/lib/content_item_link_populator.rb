class ContentItemLinkPopulator
  def self.create_or_replace(source_content_id, links)
    content_item_links = ContentItemLink.where(source: source_content_id)

    if links.nil? || links.empty?
      delete_old_content_item_links(source_content_id)
    elsif content_item_links.empty?
      add_content_item_links(source_content_id, links)
    else
      delete_old_content_item_links(source_content_id)
      add_content_item_links(source_content_id, links)
    end
  end

  def self.add_content_item_links(source_content_id, links)
    links.each do |link_type, links|
      links.each do |link|
        ContentItemLink.new(source: source_content_id, link_type: link_type, target: link).save!
      end
    end
  end

  def self.delete_old_content_item_links(source_content_id)
    ContentItemLink.where(source: source_content_id).delete_all
  end
end
