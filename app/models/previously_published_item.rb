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

  delegate :content_id, to: :previously_published_item

  def user_facing_version
    previously_published_item.user_facing_version + 1
  end

  delegate :first_published_at, to: :previously_published_item

  delegate :publishing_api_first_published_at, to: :previously_published_item

  delegate :last_edited_at, to: :previously_published_item

  delegate :major_published_at, to: :previously_published_item

  delegate :public_updated_at, to: :previously_published_item

  def previous_base_path
    previously_published_item.base_path
  end

  delegate :routes, to: :previously_published_item

  def path_has_changed?
    previous_base_path != base_path
  end

  delegate :links, to: :previously_published_item

  class NoPreviousPublishedItem
    def user_facing_version
      1
    end

    def links
      []
    end

    def path_has_changed?
      false
    end

    def previous_base_path; end

    def routes; end

    def content_id; end

    def first_published_at; end

    def publishing_api_first_published_at; end

    def major_published_at; end

    def public_updated_at; end
  end
end
