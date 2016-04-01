module Queries
  class LinkSets
    def call
      {
        "parent": {
          expanded_links: [:base_url, :title],
          recurse: false
        },
        "linked_items":  {
          expanded_links: [:base_url, :title],
          recurse: true
        },
        "children": {
          expanded_links: [:change_notes],
          recurse: true
        },
        "active_top_level_browse_page": {
          expanded_links: [:title],
          recurse: true
        }
      }
    end
  end
end
