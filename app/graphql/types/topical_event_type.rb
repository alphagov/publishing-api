# frozen_string_literal: true

module Types
  class TopicalEventType < Types::EditionType
    description "A topical event"
    field :start_date, String
    field :end_date, String
    field :ordered_featured_documents, [Types::FeaturedDocumentType]
    field :latest, [Types::EditionType] do
      argument :first, Integer
    end
    field :consultations, [Types::EditionType]do
      argument :first, Integer
    end
    field :announcements, [Types::EditionType]do
      argument :first, Integer
    end
    field :guidance_and_regulation, [Types::EditionType]do
      argument :first, Integer
    end

    def start_date
      object.details[:start_date]
    end

    def end_date
      object.details[:end_date]
    end

    def ordered_featured_documents
      object.details[:ordered_featured_documents]
    end

    def latest(first:)
      linked_content_ids = dataloader.with(Sources::LinkSetLinksToSource, %i[topical_events])
                                     .load(object.content_id)
                                     .map { |link| link.link_set.content_id }
                                     .take(first + 10) # TODO - adding 10 here as a bodge because some of the links might be to draft content items. We need to do this in one query really.
      dataloader.with(Sources::EditionSource).load_all(linked_content_ids).compact.take(first)
    end

    def consultations(first:)
      # TODO filter these just to consultations
      latest(first:)
    end

    def announcements(first:)
      # TODO filter these just to announcements
      latest(first:)
    end

    def guidance_and_regulation(first:)
      # TODO filter these just to guidance and regulation
      latest(first:)
    end
  end
end
