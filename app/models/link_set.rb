class LinkSet < ApplicationRecord
  include FindOrCreateLocked

  # NOTE: link sets can have more than one document, because there
  # can be multiple documents with the same content_id and different locales
  has_many :documents, foreign_key: "content_id", primary_key: "content_id", inverse_of: :link_set
  has_many :links, -> { order(link_type: :asc, position: :asc) }, dependent: :destroy

  # We could define the `==` method on `Link` to perform this check but that
  # breaks the strict definition of a model instance being a representation of
  # a specific row in the database as it would allow two different rows to
  # equate.
  ComparableLink = Struct.new(:link) do
    delegate :target_content_id, :link_type, :position, to: :link

    def hash
      [target_content_id, link_type, position].hash
    end

    def eql?(other)
      target_content_id == other.target_content_id &&
        link_type == other.link_type &&
        position == other.position
    end
  end

  def links_changed?(other_links)
    links_set = links.map { |link| ComparableLink.new(link) }.to_set
    other_links_set = other_links.map { |link| ComparableLink.new(link) }.to_set
    links_set != other_links_set
  end
end
