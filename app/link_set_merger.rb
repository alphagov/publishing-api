module LinkSetMerger
  def self.merge_links_into(content_item)
    merged_result = content_item.as_json

    link_set = LinkSet.find_by(content_id: content_item.content_id)
    merged_result.merge!(links: link_set.links) if link_set && link_set.links

    merged_result.deep_symbolize_keys
  end
end
