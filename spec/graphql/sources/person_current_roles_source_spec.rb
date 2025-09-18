RSpec.describe Sources::PersonCurrentRolesSource do
  include MinistersIndexHelpers

  it "returns the current roles for a person" do
    person_1 = create_person("Person 1")
    role_1 = create_role("Role 1")
    role_2 = create_role("Role 2")
    role_3 = create_role("Role 3")
    appoint_person_to_role(person_1, role_1)
    appoint_person_to_role(person_1, role_2, current: false)
    appoint_person_to_role(person_1, role_3)

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class).request(person_1.content_id)

      expect(request.load).to match_array([role_1, role_3])
    end
  end

  it "returns roles ordered by the `position` of the role_appointment->role links" do
    person = create_person("Person")
    role_0 = create_role("Role 0")
    role_1 = create_role("Role 1")
    role_2 = create_role("Role 2")

    # appoint person to role
    role_appointment = create(
      :live_edition,
      document_type: "role_appointment",
      details: { current: true },
    )
    link_set = create(:link_set, content_id: role_appointment.content_id)
    create(:link, link_type: "person", target_content_id: person.content_id, link_set:)
    create(:link, position: 1, link_type: "role", target_content_id: role_1.content_id, link_set:)

    # appoint person to role
    role_appointment = create(
      :live_edition,
      document_type: "role_appointment",
      details: { current: true },
    )
    link_set = create(:link_set, content_id: role_appointment.content_id)
    create(:link, link_type: "person", target_content_id: person.content_id, link_set:)
    create(:link, position: 0, link_type: "role", target_content_id: role_0.content_id, link_set:)

    # appoint person to role
    role_appointment = create(
      :live_edition,
      document_type: "role_appointment",
      details: { current: true },
    )
    link_set = create(:link_set, content_id: role_appointment.content_id)
    create(:link, link_type: "person", target_content_id: person.content_id, link_set:)
    create(:link, position: 2, link_type: "role", target_content_id: role_2.content_id, link_set:)

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class).request(person.content_id)

      expect(request.load).to eq([role_0, role_1, role_2])
    end
  end

  context "when role_appointment->role links have the same `position`" do
    it "returns roles reverse-ordered by the links' `id`" do
      person = create_person("Person")
      third_linked_role = create_role("Role 3")
      first_linked_role = create_role("Role 1")
      second_linked_role = create_role("Role 2")

      # appoint person to role
      role_appointment = create(
        :live_edition,
        document_type: "role_appointment",
        details: { current: true },
      )
      link_set = create(:link_set, content_id: role_appointment.content_id)
      create(:link, link_type: "person", target_content_id: person.content_id, link_set:)
      create(:link, position: 0, link_type: "role", target_content_id: first_linked_role.content_id, link_set:)

      # appoint person to role
      role_appointment = create(
        :live_edition,
        document_type: "role_appointment",
        details: { current: true },
      )
      link_set = create(:link_set, content_id: role_appointment.content_id)
      create(:link, link_type: "person", target_content_id: person.content_id, link_set:)
      create(:link, position: 0, link_type: "role", target_content_id: second_linked_role.content_id, link_set:)

      # appoint person to role
      role_appointment = create(
        :live_edition,
        document_type: "role_appointment",
        details: { current: true },
      )
      link_set = create(:link_set, content_id: role_appointment.content_id)
      create(:link, link_type: "person", target_content_id: person.content_id, link_set:)
      create(:link, position: 0, link_type: "role", target_content_id: third_linked_role.content_id, link_set:)

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(described_class).request(person.content_id)

        expect(request.load).to eq([third_linked_role, second_linked_role, first_linked_role])
      end
    end
  end

  it "does not return draft roles for a person" do
    person_1 = create_person("Person 1")
    published_role = create_role("Role")
    draft_role = create_role("Draft role")
    non_current_draft_role = create_role("Non-current draft role")
    appoint_person_to_role(person_1, published_role)
    appoint_person_to_role(person_1, draft_role, state: "draft")
    appoint_person_to_role(person_1, non_current_draft_role, state: "draft", current: false)

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class).request(person_1.content_id)

      expect(request.load).to eq([published_role])
    end
  end

  it "does not return unpublished roles for a person" do
    person_1 = create_person("Person 1")
    published_role = create_role("Role")
    unpublished_role = create_role("Unpublished role")
    non_current_unpublished_role = create_role("Non-current unpublished role")
    appoint_person_to_role(person_1, published_role)
    appoint_person_to_role(person_1, unpublished_role, state: "unpublished")
    appoint_person_to_role(person_1, non_current_unpublished_role, state: "unpublished", current: false)

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class).request(person_1.content_id)

      expect(request.load).to eq([published_role])
    end
  end
end
