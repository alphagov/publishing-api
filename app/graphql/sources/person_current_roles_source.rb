module Sources
  class PersonCurrentRolesSource < GraphQL::Dataloader::Source
    def fetch(person_content_ids)
      all_roles = Edition
        .live
        .includes(
          document: {
            reverse_links: { # role -> role_appointment
              link_set: {
                documents: [
                  :editions, # role_appointment
                  :link_set_links, # role_appointment -> person
                ],
              },
            },
          },
        )
        .where(
          document_type: "ministerial_role",
          document: { locale: "en" },
          reverse_links: { link_type: "role" },
          documents: { locale: "en" }, # role_appointment Documents
          editions_documents: { document_type: "role_appointment" }, # role_appointment Editions
          link_set_links: { target_content_id: person_content_ids, link_type: "person" },
        )
        .where("editions_documents.details ->> 'current' = 'true'") # editions_documents is the alias that Active Record gives to the role_appointment Editions in the SQL query
        .order(reverse_links: { position: :asc })

      ids_map = person_content_ids.index_with { [] }

      all_roles.each_with_object(ids_map) { |role, hash|
        hash[person_content_id_for_role(role)] << role
      }.values
    end

  private

    def person_content_id_for_role(role)
      role_appointment_documents_for_role(role)
        .flat_map(&:link_set_links)
        .find { |link| link.link_type == "person" } # role_appointment -> person
        .target_content_id
    end

    def role_appointment_documents_for_role(role)
      role.document.reverse_links
        .select { |link| link.link_type == "role" } # role -> role_appointment
        .flat_map { |link| link.link_set.documents }
    end
  end
end
