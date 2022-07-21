class LinkChangeService
  attr_reader :action, :before_links, :after_links

  def initialize(action, before_links, after_links)
    @action = action
    @before_links = before_links
    @after_links = after_links
  end

  def record
    before_set = Set.new(before_links.map { |link| [link.target_content_id, link.link_type] })
    after_set = Set.new(after_links.map { |link| [link.target_content_id, link.link_type] })

    after_links.each do |link|
      unless before_set.include?([link.target_content_id, link.link_type])
        create_link_change(link: link, change: :add)
      end
    end

    before_links.each do |link|
      unless after_set.include?([link.target_content_id, link.link_type])
        create_link_change(link: link, change: :remove)
      end
    end
  end

private

  def create_link_change(link:, change:)
    LinkChange.create!(
      source_content_id: action.content_id,
      target_content_id: link.target_content_id,
      link_type: link.link_type,
      change: change,
      action: action,
    )
  end
end
