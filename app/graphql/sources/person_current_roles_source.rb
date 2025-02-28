module Sources
  class PersonCurrentRolesSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize
      @content_store = :live
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(person_content_ids_and_selections)
      person_content_ids = []
      ids_map = {}
      all_selections = {
        role_appointment_links: %i[target_content_id],
        documents: %i[content_id],
      }
      editions_selections = Set.new

      person_content_ids_and_selections.each do |person_content_id, selections|
        person_content_ids << person_content_id
        ids_map[person_content_id] = []
        editions_selections.merge(selections)
      end

      all_selections[:editions] = editions_selections.to_a

      all_roles = Edition
        .joins(document: [reverse_links: :link_set])
        .joins(
          <<~SQL,
            INNER JOIN documents role_appointment_documents
            ON role_appointment_documents.content_id = link_sets.content_id
          SQL
        )
        .joins(
          <<~SQL,
            INNER JOIN editions role_appointment_editions
            ON role_appointment_editions.document_id = role_appointment_documents.id
          SQL
        )
        .joins(
          <<~SQL,
            INNER JOIN link_sets role_appointment_link_sets
            ON role_appointment_link_sets.content_id = role_appointment_documents.content_id
          SQL
        )
        .joins(
          <<~SQL,
            INNER JOIN links role_appointment_links
            ON role_appointment_links.link_set_id = role_appointment_link_sets.id
          SQL
        )
        .where(
          editions: {
            content_store: @content_store,
            document_type: "ministerial_role",
          },
          documents: { locale: "en" },
          reverse_links: { link_type: "role" },
          role_appointment_documents: { locale: "en" },
          role_appointment_editions: {
            content_store: @content_store,
            document_type: "role_appointment",
          },
          role_appointment_links: {
            target_content_id: person_content_ids,
            link_type: "person",
          },
        )
        .where("role_appointment_editions.details ->> 'current' = 'true'")
        .order(reverse_links: { position: :asc })
        .select(all_selections)

      all_roles.each_with_object(ids_map) { |role, hash|
        hash[role.target_content_id] << role
      }.values
    end
  end
end
