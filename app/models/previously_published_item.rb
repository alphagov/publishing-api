class PreviouslyPublishedItem
  def initialize(document, base_path, put_content)
    @document = document
    @base_path = base_path
    @put_content = put_content
  end

  def call
    previously_published_item ? self : NoPreviousPublishedItem.new
  end

  attr_reader :document, :base_path, :put_content

  def previously_published_item
    document.published_or_unpublished
  end

  def user_facing_version
    previously_published_item.user_facing_version + 1
  end

  def set_first_published_at?
    true
  end

  def first_published_at
    previously_published_item.first_published_at
  end

  def set_last_edited_at?
    true
  end

  def last_edited_at
    previously_published_item.last_edited_at
  end

  def previous_base_path
    previously_published_item.base_path
  end

  def routes
    previously_published_item.routes
  end

  def path_has_changed?
    previous_base_path != base_path
  end

  def links
    previously_published_item.links
  end

  class NoPreviousPublishedItem
    def user_facing_version
      1
    end

    def links
      []
    end

    def set_first_published_at?
      false
    end

    def set_last_edited_at?
      false
    end

    def path_has_changed?
      false
    end

    def previous_base_path
    end

    def routes
    end
  end
end
